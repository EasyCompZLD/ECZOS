#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 build host.\n' >&2
    exit 2
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi
if [[ ${ECZOS_HARDWARE_QUALIFICATION:-} != 1 ]]; then
    printf 'Set ECZOS_HARDWARE_QUALIFICATION=1 to resume the hardware test ISO.\n' >&2
    exit 2
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"
BUILD_DIR="$IMAGE_DIR/.build"
ARTIFACT_DIR="$BUILD_DIR/artifacts"
LOG_DIR="$BUILD_DIR/logs"
RELEASE_DIR="$ROOT_DIR/packages/eczos-release"
BUILD_ID=$(date -u +%Y%m%d-%H%M%S)
ISO_NAME="ECZOS-hardware-qualification-amd64-${BUILD_ID}.iso"

if [[ ! -d "$IMAGE_DIR/chroot" || \
      ! -f "$BUILD_DIR/chroot_package-lists.install" || \
      -f "$BUILD_DIR/binary_rootfs" ]]; then
    printf 'No resumable pre-filesystem live-build state was found.\n' >&2
    exit 2
fi

for command_name in lb dpkg-buildpackage dpkg-deb dpkg-parsechangelog sha256sum; do
    command -v "$command_name" >/dev/null || {
        printf 'Missing build dependency: %s\n' "$command_name" >&2
        exit 1
    }
done

"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
mkdir -p "$ARTIFACT_DIR" "$LOG_DIR"

if [[ ! -f "$BUILD_DIR/chroot_install-packages.install" ]]; then
    find "$RELEASE_DIR/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$RELEASE_DIR/debian/rules" "$RELEASE_DIR/debian/preinst" \
        "$RELEASE_DIR/debian/postinst" "$RELEASE_DIR/debian/postrm"
    (cd "$RELEASE_DIR" && dpkg-buildpackage -us -uc -b)

    version=$(dpkg-parsechangelog -l"$RELEASE_DIR/debian/changelog" -S Version)
    release_deb="eczos-release_${version}_all.deb"
    built_release="$ROOT_DIR/packages/$release_deb"
    test -f "$built_release"
    install -m 0644 "$built_release" "$IMAGE_DIR/config/packages.chroot/$release_deb"
    install -m 0644 "$built_release" "$IMAGE_DIR/chroot/tmp/$release_deb"

    # Unpack only: the preserved live-build APT stage will configure this
    # package and the previously unpacked dependencies when the build resumes.
    chroot "$IMAGE_DIR/chroot" dpkg --unpack "/tmp/$release_deb"
    rm -f "$IMAGE_DIR/chroot/tmp/$release_deb"
elif [[ ! -f "$BUILD_DIR/chroot_hooks" ]]; then
    # A failed install can restore live-build's bootstrap cache while retaining
    # its completed install marker. Reinstall the newest staged version of each
    # local package before resuming the hook stage.
    recovery_dir="$IMAGE_DIR/chroot/tmp/eczos-image-recovery"
    install -d -m 0755 "$recovery_dir"
    find "$recovery_dir" -maxdepth 1 -type f -name '*.deb' -delete

    declare -A selected_deb=()
    declare -A selected_version=()
    for candidate in "$IMAGE_DIR/config/packages.chroot"/*.deb; do
        package=$(dpkg-deb -f "$candidate" Package)
        candidate_version=$(dpkg-deb -f "$candidate" Version)
        if [[ -z ${selected_version[$package]:-} ]] || \
           dpkg --compare-versions "$candidate_version" gt "${selected_version[$package]}"; then
            selected_deb[$package]=$candidate
            selected_version[$package]=$candidate_version
        fi
    done

    recovery_packages=()
    for package in "${!selected_deb[@]}"; do
        filename=$(basename "${selected_deb[$package]}")
        install -m 0644 "${selected_deb[$package]}" "$recovery_dir/$filename"
        recovery_packages+=("/tmp/eczos-image-recovery/$filename")
    done
    ((${#recovery_packages[@]} >= 11)) || {
        printf 'Expected at least 11 staged ECZOS and vendor packages; found %s.\n' \
            "${#recovery_packages[@]}" >&2
        exit 1
    }

    chroot "$IMAGE_DIR/chroot" apt-get install -y "${recovery_packages[@]}"
    for package in \
        eczos-branding eczos-sddm-theme eczos-plymouth-theme \
        eczos-desktop-defaults eczos-release eczos-windows-core \
        eczos-gaming-core eczos-platform-tools eczos-desktop-apps \
        eczos-desktop softmaker-freeoffice-2024; do
        chroot "$IMAGE_DIR/chroot" dpkg-query -W -f='${Status}\n' "$package" \
            | grep -Fx 'install ok installed'
    done
    test -s "$IMAGE_DIR/chroot/usr/share/plymouth/themes/eczos/eczos.plymouth"
    find "$recovery_dir" -maxdepth 1 -type f -name '*.deb' -delete
    rmdir "$recovery_dir"
fi

for package in \
    eczos-branding eczos-sddm-theme eczos-plymouth-theme \
    eczos-desktop-defaults eczos-release eczos-windows-core \
    eczos-gaming-core eczos-platform-tools eczos-desktop-apps \
    eczos-desktop softmaker-freeoffice-2024; do
    chroot "$IMAGE_DIR/chroot" dpkg-query -W -f='${Status}\n' "$package" \
        | grep -Fx 'install ok installed'
done
test -s "$IMAGE_DIR/chroot/usr/share/plymouth/themes/eczos/eczos.plymouth"

# chroot_archives runs APT as _apt during its removal phase. Runtime keyrings
# copied from SMB-hosted sources must therefore not retain owner-only modes.
chmod 0644 \
    "$IMAGE_DIR/chroot/usr/share/keyrings/softmaker-archive-keyring.asc" \
    "$IMAGE_DIR/chroot/etc/apt/sources.list.d/softmaker.list"
chroot "$IMAGE_DIR/chroot" runuser -u _apt -- \
    test -r /usr/share/keyrings/softmaker-archive-keyring.asc

export MKSQUASHFS_OPTIONS="-processors $(nproc)"
if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_DATE_EPOCH=$(git -C "$ROOT_DIR" log -1 --format=%ct)
else
    SOURCE_DATE_EPOCH=$(date -u +%s)
fi
export SOURCE_DATE_EPOCH

cd "$IMAGE_DIR"
./auto/build 2>&1 | tee "$LOG_DIR/hardware-qualification-resume-${BUILD_ID}.log"

BUILT_ISO="$IMAGE_DIR/live-image-amd64.hybrid.iso"
if [[ ! -f "$BUILT_ISO" ]]; then
    printf 'live-build finished without the expected ISO.\n' >&2
    exit 1
fi

install -m 0644 "$BUILT_ISO" "$ARTIFACT_DIR/$ISO_NAME"
(cd "$ARTIFACT_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
printf '\nHardware-qualification ISO completed (not a public release):\n%s\n' \
    "$ARTIFACT_DIR/$ISO_NAME"
cat "$ARTIFACT_DIR/$ISO_NAME.sha256"
