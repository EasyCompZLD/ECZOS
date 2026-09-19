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
PACKAGES=(
    eczos-archive-keyring
    eczos-release
    eczos-branding
    eczos-desktop-defaults
    eczos-platform-tools
    eczos-windows-core
    eczos-gaming-core
    eczos-recovery-media
    eczos-desktop-apps
    eczos-installer
    eczos-oobe
    eczos-desktop
)

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
    for data_dir in applications assets branding config keyrings polkit product qml xdg; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
done

debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    package_arch=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ $package_arch == all ]] || package_arch=$(dpkg-architecture -qDEB_HOST_ARCH)
    debs+=("$ROOT_DIR/packages/${package}_${version}_${package_arch}.deb")
done
apt-get install -y "${debs[@]}"

"$ROOT_DIR/tests/smoke/archive-keyring-package.sh"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/branding-package.sh"
"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
"$ROOT_DIR/tests/smoke/windows-core-package.sh"
"$ROOT_DIR/tests/smoke/gaming-core-package.sh"
"$ROOT_DIR/tests/smoke/recovery-media-package.sh"
"$ROOT_DIR/tests/smoke/installer-package.sh"
"$ROOT_DIR/tests/smoke/oobe-package.sh"
"$ROOT_DIR/tests/smoke/desktop-apps-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

printf '\nECZOS interface, recovery, OOBE and installer UX batch passed.\n'
printf 'Open ECZOS Instellingen and ECZOS Herstelmedium for the visual check.\n'
