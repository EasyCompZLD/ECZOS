#!/usr/bin/env bash
set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'Debian 13 (trixie) is required.\n' >&2; exit 2;
}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.1}
BUNDLE_DIR="$RELEASE_DIR/packages"
IMAGE_DIR="$RELEASE_DIR/images"
BUILD_BASE=${ECZOS_BUILD_BASE:-/srv/eczos-builds}
PREPARE_ONLY=false
case ${1:-} in
    --prepare-only) PREPARE_ONLY=true ;;
    '') ;;
    *) printf 'Usage: %s [--prepare-only]\n' "$0" >&2; exit 2 ;;
esac

for command_name in lb rsync flock sha256sum xorriso unsquashfs; do
    command -v "$command_name" >/dev/null || {
        printf 'Missing build dependency: %s\n' "$command_name" >&2; exit 1;
    }
done
[[ ! -e "$ROOT_DIR/image/BUILD_BLOCKED.md" ]] || {
    printf 'Release build remains blocked by image/BUILD_BLOCKED.md.\n' >&2; exit 2;
}
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/verify-release-0.1.1.sh"
[[ -s "$BUNDLE_DIR/SHA256SUMS" ]] || {
    printf 'Build the release package bundle first.\n' >&2; exit 1;
}
(cd "$BUNDLE_DIR" && sha256sum --check SHA256SUMS)

install -d -m 2775 "$BUILD_BASE"
exec 9>"$BUILD_BASE/build.lock"
flock -n 9 || { printf 'Another isolated ECZOS build is running.\n' >&2; exit 1; }
AVAILABLE_KB=$(df -Pk "$BUILD_BASE" | awk 'END {print $4}')
(( AVAILABLE_KB >= 60 * 1024 * 1024 )) || {
    printf 'At least 60 GiB free space is required.\n' >&2; exit 1;
}

RUN_DIR=$(mktemp -d "$BUILD_BASE/release-0.1.1-$(date -u +%Y%m%d-%H%M%S)-XXXXXX")
WORK_DIR="$RUN_DIR/image"
mkdir -p "$WORK_DIR/config" "$WORK_DIR/config/packages.chroot" "$RUN_DIR/artifacts"
exec > >(tee "$RUN_DIR/build.log") 2>&1
trap 'rc=$?; printf "Build failed (%s). Preserved: %s\n" "$rc" "$RUN_DIR" >&2; exit "$rc"' ERR
printf 'Build directory: %s\n' "$RUN_DIR"

for input in includes.chroot package-lists hooks bootloaders; do
    rsync -a --exclude='8*.hook.chroot' "$ROOT_DIR/image/config/$input" "$WORK_DIR/config/"
done
install -m 0644 "$BUNDLE_DIR"/*.deb "$WORK_DIR/config/packages.chroot/"
"$ROOT_DIR/scripts/verify-staged-package-versions-vm.sh" "$WORK_DIR/config/packages.chroot"
install -m 0755 "$ROOT_DIR/image/auto/config" "$RUN_DIR/configure-image"
cd "$WORK_DIR"
ECZOS_ISO_VOLUME=ECZOS_0_1_1_AMD64 \
ECZOS_ISO_APPLICATION='ECZOS 0.1.1' "$RUN_DIR/configure-image"

if $PREPARE_ONLY; then
    printf 'Release preparation passed; no live-build was started.\n'
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive
export MKSQUASHFS_OPTIONS="-processors $(nproc)"
lb build noauto
test -s live-image-amd64.hybrid.iso
test -s binary/live/filesystem.squashfs
for package in eczos-desktop eczos-oobe eczos-installer calamares \
    softmaker-freeoffice-2024 wine64; do
    grep -q "^${package}[[:space:]:]" binary/live/filesystem.packages
done

ISO_INSPECTION_DIR="$RUN_DIR/iso-inspection"
mkdir -p "$ISO_INSPECTION_DIR"
xorriso -osirrox on -indev live-image-amd64.hybrid.iso \
    -extract /boot/grub/grub.cfg "$ISO_INSPECTION_DIR/grub.cfg" \
    -extract /boot/grub/splash.png "$ISO_INSPECTION_DIR/splash.png" \
    > "$RUN_DIR/iso-inspection.log" 2>&1
grep -Fq 'menuentry "ECZOS proberen"' "$ISO_INSPECTION_DIR/grub.cfg"
grep -Fq 'menuentry "ECZOS installeren"' "$ISO_INSPECTION_DIR/grub.cfg"
cmp -s "$ROOT_DIR/packages/eczos-branding/assets/wallpapers/eczoswallpaper-dark.png" \
    "$ISO_INSPECTION_DIR/splash.png"

if unsquashfs -ll binary/live/filesystem.squashfs | \
   grep -Eq '/(etc/skel|home/[^/]+)/(Desktop|Bureaublad)/calamares-install-debian\.desktop$'; then
    printf 'Legacy Debian installer launcher leaked into the ISO tree.\n' >&2
    exit 1
fi

# Guard the exact regression that allowed calamares-settings-debian to switch
# the live installer back to stock branding.
unsquashfs -cat binary/live/filesystem.squashfs \
    usr/share/eczos/installer/calamares/settings.conf | grep -Fxq 'branding: eczos'
unsquashfs -cat binary/live/filesystem.squashfs usr/bin/eczos-installer | \
    grep -Fq -- 'calamares --config /usr/share/eczos/installer/calamares'
unsquashfs -cat binary/live/filesystem.squashfs \
    usr/lib/eczos/release/eczos-release | grep -Fxq 'ECZOS_CHANNEL=stable'

ISO_NAME="ECZOS-0.1.1-amd64.iso"
install -m 0644 live-image-amd64.hybrid.iso "$RUN_DIR/artifacts/$ISO_NAME"
(cd "$RUN_DIR/artifacts" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
install -d -m 2775 "$IMAGE_DIR"
install -m 0644 "$RUN_DIR/artifacts/$ISO_NAME" "$IMAGE_DIR/$ISO_NAME"
(cd "$IMAGE_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
printf 'Release ISO completed: %s\n' "$IMAGE_DIR/$ISO_NAME"
cat "$IMAGE_DIR/$ISO_NAME.sha256"
