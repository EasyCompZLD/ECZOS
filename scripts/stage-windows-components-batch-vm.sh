#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
PACKAGES=(eczos-windows-core eczos-platform-tools)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    build-essential cmake debhelper devscripts dpkg-dev extra-cmake-modules gettext \
    libkf6auth-dev libkf6config-dev libkf6coreaddons-dev libkf6kcmutils-dev \
    lintian qt6-base-dev qt6-declarative-dev qt6-l10n-tools qt6-tools-dev winetricks

bash "$ROOT_DIR/scripts/verify-source.sh"

declare -a package_debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    find "$package_dir/bin" "$package_dir/lib" -type f -exec chmod 0755 {} + 2>/dev/null || true
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ "$architecture" = all ]] || architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
    package_debs+=("$ROOT_DIR/packages/${package}_${version}_${architecture}.deb")
done

apt-get install -y "${package_debs[@]}"
bash "$ROOT_DIR/tests/smoke/windows-core-package.sh"
bash "$ROOT_DIR/tests/smoke/platform-tools-package.sh"

printf '\nECZOS managed Windows components batch passed.\n'
printf 'Open ECZOS Settings > Windows apps and use Components on an installed app.\n'
