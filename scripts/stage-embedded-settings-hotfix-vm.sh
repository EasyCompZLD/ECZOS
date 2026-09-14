#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-platform-tools eczos-desktop)
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

platform_version=$(dpkg-parsechangelog -l"$ROOT_DIR/packages/eczos-platform-tools/debian/changelog" -S Version)
desktop_version=$(dpkg-parsechangelog -l"$ROOT_DIR/packages/eczos-desktop/debian/changelog" -S Version)
platform_deb="$ROOT_DIR/packages/eczos-platform-tools_${platform_version}_amd64.deb"
desktop_deb="$ROOT_DIR/packages/eczos-desktop_${desktop_version}_all.deb"

test -f "$platform_deb"
platform_contents=$(dpkg-deb -c "$platform_deb")
grep -Fq './usr/bin/eczos-system-settings' <<<"$platform_contents"
apt-get install -y "$platform_deb" "$desktop_deb"

"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

printf '\nEmbedded ECZOS system-settings hotfix passed.\n'
