#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-platform-batch.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

PACKAGES=(eczos-desktop-defaults eczos-release eczos-desktop)
INSTALL_FILES=()

for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    if [[ -d "$package_dir/bin" ]]; then
        find "$package_dir/bin" -type f -exec chmod 0755 {} +
    fi
    if [[ -d "$package_dir/lib" ]]; then
        find "$package_dir/lib" -type f -exec chmod 0755 {} +
    fi
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    built="$OUTPUT_DIR/${package}_${version}_all.deb"
    test -f "$built"
    staged="$TEMP_DIR/${package}.deb"
    install -m 0644 "$built" "$staged"
    INSTALL_FILES+=("$staged")
done

lintian "${INSTALL_FILES[@]}" || true
apt-get install -y "${INSTALL_FILES[@]}"
"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

printf '\nECZOS platform batch installed successfully.\n'
printf 'Log out and back in once to apply the corrected blue wallpaper.\n'
