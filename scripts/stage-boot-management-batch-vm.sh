#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-boot-tools eczos-platform-tools eczos-desktop)
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends grub-common os-prober efibootmgr debhelper devscripts lintian \
    cmake extra-cmake-modules libkf6auth-dev libkf6config-dev libkf6coreaddons-dev libkf6kcmutils-dev \
    qt6-base-dev qt6-declarative-dev qt6-l10n-tools qt6-tools-dev
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/audit-package-architecture.sh"
debs=()
for package in "${PACKAGES[@]}"; do
    dir="$ROOT_DIR/packages/$package"
    find "$dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$dir/debian/rules"
    for maintainer in preinst postinst prerm postrm; do [[ ! -f "$dir/debian/$maintainer" ]] || chmod 0755 "$dir/debian/$maintainer"; done
    for executable_dir in bin lib; do [[ ! -d "$dir/$executable_dir" ]] || find "$dir/$executable_dir" -type f -exec chmod 0755 {} +; done
    (cd "$dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$dir/debian/changelog" -S Version)
    arch=$(awk '/^Architecture:/ {print $2; exit}' "$dir/debian/control"); [[ "$arch" = all ]] || arch=$(dpkg-architecture -qDEB_HOST_ARCH)
    deb="$ROOT_DIR/packages/${package}_${version}_${arch}.deb"; test -f "$deb"; debs+=("$deb")
done
lintian "${debs[@]}" || true
apt-get install -y "${debs[@]}"
"$ROOT_DIR/tests/smoke/boot-tools-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
printf '\nECZOS safe boot-management batch passed. No boot menu was changed.\n'
printf 'Review detection in ECZOS Settings before choosing Update boot menu safely.\n'
