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
SMOKE_TESTS=(
    archive-keyring-package.sh
    release-package.sh
    branding-package.sh
    desktop-defaults-package.sh
    platform-core-package.sh
    firewall-package.sh
    platform-tools-package.sh
    windows-core-package.sh
    gaming-core-package.sh
    recovery-media-package.sh
    installer-package.sh
    oobe-package.sh
    desktop-apps-package.sh
    desktop-metapackage.sh
)

run_smoke_tests() {
    local test_name
    for test_name in "${SMOKE_TESTS[@]}"; do
        # Invoke through Bash so a checkout on an SMB share cannot break the
        # test run merely by dropping the executable bit.
        bash "$ROOT_DIR/tests/smoke/$test_name"
    done
}

case ${1:-} in
    --tests-only)
        bash "$ROOT_DIR/scripts/verify-source.sh"
        run_smoke_tests
        printf '\nECZOS interface, recovery, OOBE and installer UX batch passed.\n'
        printf 'Open ECZOS Instellingen and ECZOS Herstelmedium for the visual check.\n'
        exit 0
        ;;
    '')
        ;;
    *)
        printf 'Usage: %s [--tests-only]\n' "$0" >&2
        exit 2
        ;;
esac

PACKAGES=(
    eczos-archive-keyring
    eczos-release
    eczos-branding
    eczos-desktop-defaults
    eczos-platform-core
    eczos-firewall
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
bash "$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
bash "$ROOT_DIR/scripts/verify-source.sh"

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
    for data_dir in applications assets branding config firewalld keyrings polkit product qml runtime-definitions schema systemd xdg; do
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

run_smoke_tests

printf '\nECZOS interface, recovery, OOBE and installer UX batch passed.\n'
printf 'Open ECZOS Instellingen and ECZOS Herstelmedium for the visual check.\n'
