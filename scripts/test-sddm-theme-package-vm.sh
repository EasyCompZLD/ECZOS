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
BRANDING_DIR="$ROOT_DIR/packages/eczos-branding"
THEME_DIR="$ROOT_DIR/packages/eczos-sddm-theme"
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-sddm-test.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

normalize_package_modes() {
    local package_dir=$1
    chmod 0644 \
        "$package_dir/debian/changelog" \
        "$package_dir/debian/control" \
        "$package_dir/debian/copyright" \
        "$package_dir/debian/install" \
        "$package_dir/debian/source/format"
    if [[ -f "$package_dir/debian/links" ]]; then
        chmod 0644 "$package_dir/debian/links"
    fi
    chmod 0755 "$package_dir/debian/rules"
}

normalize_package_modes "$BRANDING_DIR"
normalize_package_modes "$THEME_DIR"
find "$BRANDING_DIR/assets" "$THEME_DIR/config" "$THEME_DIR/theme" \
    -type f -exec chmod 0644 {} +

(cd "$BRANDING_DIR" && dpkg-buildpackage -us -uc -b)
(cd "$THEME_DIR" && dpkg-buildpackage -us -uc -b)

BRANDING_PACKAGE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    -name 'eczos-branding_*_all.deb' -print -quit)
THEME_PACKAGE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    -name 'eczos-sddm-theme_*_all.deb' -print -quit)

if [[ -z "$BRANDING_PACKAGE" || -z "$THEME_PACKAGE" ]]; then
    printf 'Expected package output is missing.\n' >&2
    exit 1
fi

install -m 0644 "$BRANDING_PACKAGE" "$TEMP_DIR/eczos-branding.deb"
install -m 0644 "$THEME_PACKAGE" "$TEMP_DIR/eczos-sddm-theme.deb"

lintian "$TEMP_DIR/eczos-branding.deb" "$TEMP_DIR/eczos-sddm-theme.deb" || true
apt-get install -y "$TEMP_DIR/eczos-branding.deb" "$TEMP_DIR/eczos-sddm-theme.deb"
"$ROOT_DIR/tests/smoke/sddm-theme-package.sh"

apt-get purge -y eczos-sddm-theme eczos-branding

test ! -e /etc/sddm.conf.d/90-eczos-theme.conf
test ! -e /usr/share/sddm/themes/eczos
test ! -e /usr/share/eczos/branding
dpkg --audit
apt-get check

printf 'eczos-sddm-theme lifecycle test passed\n'
