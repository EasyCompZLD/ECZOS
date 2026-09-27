#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2
    exit 2
fi
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(
    eczos-platform-core
    eczos-desktop-defaults
    eczos-platform-tools
    eczos-windows-core
    eczos-desktop-apps
    eczos-desktop
)
SMOKE_TESTS=(
    platform-core-package.sh
    desktop-defaults-package.sh
    platform-tools-package.sh
    windows-core-package.sh
    desktop-apps-package.sh
    desktop-metapackage.sh
)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    build-essential cmake debhelper devscripts dpkg-dev extra-cmake-modules gettext \
    libkf6auth-dev libkf6config-dev libkf6coreaddons-dev libkf6kcmutils-dev \
    lintian qt6-base-dev qt6-declarative-dev qt6-l10n-tools qt6-tools-dev

bash "$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
bash "$ROOT_DIR/scripts/verify-source.sh"

declare -a package_debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for executable_dir in bin lib; do
        if [[ -d "$package_dir/$executable_dir" ]]; then
            find "$package_dir/$executable_dir" -type f -exec chmod 0755 {} +
        fi
    done
    for data_dir in applications config qml runtime-definitions schema systemd xdg; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ "$architecture" = all ]] || architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
    package_debs+=("$ROOT_DIR/packages/${package}_${version}_${architecture}.deb")
done

apt-get install -y "${package_debs[@]}"
for smoke_test in "${SMOKE_TESTS[@]}"; do
    bash "$ROOT_DIR/tests/smoke/$smoke_test"
done

printf '\nECZOS foundation, Windows schema 2 and Night Light appearance batch passed.\n'
printf 'The Night Light synchronization service starts automatically at the next graphical login.\n'
