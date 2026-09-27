#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-archive-keyring eczos-release eczos-platform-core eczos-platform-tools eczos-windows-core eczos-gaming-core eczos-recovery-media eczos-desktop)
export DEBIAN_FRONTEND=noninteractive

"$ROOT_DIR/scripts/verify-source.sh"
dpkg-checkbuilddeps "$ROOT_DIR/packages/eczos-platform-tools/debian/control"

for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    find "$package_dir/bin" -type f -exec chmod 0755 {} + 2>/dev/null || true
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
done

declare -a package_debs=()
for package in "${PACKAGES[@]}"; do
    version=$(dpkg-parsechangelog -l"$ROOT_DIR/packages/$package/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ { print $2; exit }' "$ROOT_DIR/packages/$package/debian/control")
    [[ $architecture == all ]] || architecture=$(dpkg --print-architecture)
    package_debs+=("$ROOT_DIR/packages/${package}_${version}_${architecture}.deb")
done
platform_deb=
for package_deb in "${package_debs[@]}"; do
    if [[ $(dpkg-deb -f "$package_deb" Package) == eczos-platform-tools ]]; then
        platform_deb=$package_deb
        break
    fi
done

test -n "$platform_deb"
test -f "$platform_deb"
platform_contents=$(dpkg-deb -c "$platform_deb")
grep -Fq './usr/bin/eczos-system-settings' <<<"$platform_contents"
for package_deb in "${package_debs[@]}"; do
    test -f "$package_deb"
done
apt-get install -y "${package_debs[@]}"

"$ROOT_DIR/tests/smoke/archive-keyring-package.sh"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/platform-core-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
"$ROOT_DIR/tests/smoke/windows-core-package.sh"
"$ROOT_DIR/tests/smoke/gaming-core-package.sh"
"$ROOT_DIR/tests/smoke/recovery-media-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

printf '\nEmbedded ECZOS system-settings hotfix passed.\n'
