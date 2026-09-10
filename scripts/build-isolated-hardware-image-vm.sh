#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ $(id -u) == 0 ]] || { echo 'Run as root on the Debian build host.' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || exit 2
[[ ${ECZOS_HARDWARE_QUALIFICATION:-} == 1 ]] || {
    echo 'Set ECZOS_HARDWARE_QUALIFICATION=1 (hardware test ISO, not a public release).' >&2
    exit 2
}
PREPARE_ONLY=false
case ${1:-} in
    --prepare-only) PREPARE_ONLY=true ;;
    '') ;;
    *) echo 'Usage: build-isolated-hardware-image-vm.sh [--prepare-only]' >&2; exit 2 ;;
esac
for dependency in lb rsync flock sha256sum xorriso dpkg-buildpackage lintian; do
    command -v "$dependency" >/dev/null || { echo "Missing: $dependency" >&2; exit 1; }
done

# Keep output and stage state off the source share. Never reuse an old work tree.
BUILD_BASE=/srv/eczos-builds
mkdir -p "$BUILD_BASE"
exec 9>"$BUILD_BASE/build.lock"
flock -n 9 || { echo 'Another isolated ECZOS build is running.' >&2; exit 1; }
AVAILABLE_KB=$(df -Pk "$BUILD_BASE" | awk 'END {print $4}')
(( AVAILABLE_KB >= 60 * 1024 * 1024 )) || {
    echo 'At least 60 GiB free space is required for a new build.' >&2; exit 1;
}
RUN_DIR=$(mktemp -d "$BUILD_BASE/run-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")
WORK_DIR="$RUN_DIR/image"
mkdir -p "$WORK_DIR/config" "$RUN_DIR/artifacts"
exec > >(tee "$RUN_DIR/build.log") 2>&1
trap 'rc=$?; printf "Build failed (%s). Preserve this directory for diagnosis: %s\n" "$rc" "$RUN_DIR" >&2; exit "$rc"' ERR
echo "Build directory: $RUN_DIR"
export DEBIAN_FRONTEND=noninteractive
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"

# Explicit input allowlist: no generated config/common, .build, chroot, binary,
# bootstrap tree, APT indexes, or installer cache can enter the new run.
for input in includes.chroot package-lists hooks bootloaders; do
    rsync -a --exclude='8*.hook.chroot' "$ROOT_DIR/image/config/$input" "$WORK_DIR/config/"
done
install -m 0644 \
    "$ROOT_DIR/packages/eczos-branding/assets/wallpapers/eczoswallpaper-dark.png" \
    "$WORK_DIR/config/bootloaders/grub-pc/splash.png"
install -m 0755 "$ROOT_DIR/image/auto/config" "$RUN_DIR/configure-image"
cd "$WORK_DIR"
ECZOS_ISO_VOLUME=ECZOS_HWQUAL_AMD64 \
ECZOS_ISO_APPLICATION='ECZOS Hardware Qualification' "$RUN_DIR/configure-image"
if $PREPARE_ONLY; then
    echo 'Preparation passed. No packages built and no long build started.'
    exit 0
fi

"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"
"$ROOT_DIR/scripts/prepare-image-packages-vm.sh"
rsync -a "$ROOT_DIR/image/config/packages.chroot" "$WORK_DIR/config/"

# Reuse only package payloads. APT authenticates them against freshly fetched
# repository metadata; build markers and filesystem caches are never copied.
for stage in bootstrap chroot binary; do
    mkdir -p "$WORK_DIR/cache/packages.$stage"
    if [[ -d "$ROOT_DIR/image/cache/packages.$stage" ]]; then
        rsync -a --include='*.deb' --exclude='*' \
            "$ROOT_DIR/image/cache/packages.$stage/" "$WORK_DIR/cache/packages.$stage/"
    fi
done
find config -type f -exec sha256sum {} + > "$RUN_DIR/input-sha256.txt"
dpkg-query -W live-build debootstrap apt > "$RUN_DIR/build-tool-versions.txt"

# Let live-build manage its own stage order exactly once, without --force.
lb build noauto
test -s live-image-amd64.hybrid.iso
test -s binary/live/filesystem.squashfs
compgen -G 'binary/live/vmlinuz*' >/dev/null
compgen -G 'binary/live/initrd*' >/dev/null
for package in eczos-desktop eczos-oobe eczos-installer calamares \
    softmaker-freeoffice-2024 wine64; do
    grep -q "^${package}[[:space:]:]" binary/live/filesystem.packages
done
xorriso -indev live-image-amd64.hybrid.iso -report_el_torito plain \
    > "$RUN_DIR/boot-catalog.txt" 2>&1
ISO_NAME="ECZOS-hardware-qualification-$(basename "$RUN_DIR").iso"
cp --reflink=auto live-image-amd64.hybrid.iso "$RUN_DIR/artifacts/$ISO_NAME"
(cd "$RUN_DIR/artifacts" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
echo "ISO built and basic artifact checks passed: $RUN_DIR/artifacts/$ISO_NAME"
echo 'Booting and installation on real hardware still need testing.'
