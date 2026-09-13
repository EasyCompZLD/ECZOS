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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-plymouth-theme"
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-plymouth-test.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

chmod 0644 \
    "$PACKAGE_DIR/debian/changelog" \
    "$PACKAGE_DIR/debian/control" \
    "$PACKAGE_DIR/debian/copyright" \
    "$PACKAGE_DIR/debian/install" \
    "$PACKAGE_DIR/debian/links" \
    "$PACKAGE_DIR/debian/source/format" \
    "$PACKAGE_DIR/theme/eczos.plymouth"
chmod 0755 "$PACKAGE_DIR/debian/rules"
chmod 0755 "$PACKAGE_DIR/debian/preinst" "$PACKAGE_DIR/debian/postrm"
find "$PACKAGE_DIR/theme/images" -type f -exec chmod 0644 {} +

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)

PACKAGE_VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
PACKAGE_FILE="$OUTPUT_DIR/eczos-plymouth-theme_${PACKAGE_VERSION}_all.deb"
if [[ ! -f "$PACKAGE_FILE" ]]; then
    printf 'Expected package output is missing.\n' >&2
    exit 1
fi

install -m 0644 "$PACKAGE_FILE" "$TEMP_DIR/eczos-plymouth-theme.deb"
lintian "$TEMP_DIR/eczos-plymouth-theme.deb" || true
apt-get install -y "$TEMP_DIR/eczos-plymouth-theme.deb"
"$ROOT_DIR/tests/smoke/plymouth-theme-package.sh"

PREVIOUS_THEME=$(plymouth-set-default-theme)
plymouth-set-default-theme eczos
test "$(plymouth-set-default-theme)" = eczos
plymouth-set-default-theme "$PREVIOUS_THEME"
test "$(plymouth-set-default-theme)" = "$PREVIOUS_THEME"

apt-get purge -y eczos-plymouth-theme
test ! -e /usr/share/plymouth/themes/eczos
dpkg --audit
apt-get check

printf 'eczos-plymouth-theme lifecycle test passed\n'
