#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-release eczos-desktop-defaults eczos-installer eczos-oobe eczos-desktop)

export DEBIAN_FRONTEND=noninteractive
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"

for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm config; do
        if [[ -f "$package_dir/debian/$maintainer_script" ]]; then
            chmod 0755 "$package_dir/debian/$maintainer_script"
        fi
    done
    for executable_dir in bin lib; do
        if [[ -d "$package_dir/$executable_dir" ]]; then
            find "$package_dir/$executable_dir" -type f -exec chmod 0755 {} +
        fi
    done
    for data_dir in applications assets branding config lookandfeel qml xdg; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
done

debs=()
for package in "${PACKAGES[@]}"; do
    version=$(dpkg-parsechangelog -l"$ROOT_DIR/packages/$package/debian/changelog" -S Version)
    debs+=("$ROOT_DIR/packages/${package}_${version}_all.deb")
done
apt-get install -y "${debs[@]}"

"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"
"$ROOT_DIR/tests/smoke/installer-package.sh"
"$ROOT_DIR/tests/smoke/oobe-package.sh"
dpkg-query -W -f='${Status}\n' eczos-desktop | grep -Fx 'install ok installed'

printf 'ECZOS pre-build experience batch installed and verified\n'
