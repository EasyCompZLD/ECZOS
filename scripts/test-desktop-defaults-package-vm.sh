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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-desktop-defaults"
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-desktop-defaults-test.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

chmod 0644 \
    "$PACKAGE_DIR/debian/changelog" \
    "$PACKAGE_DIR/debian/control" \
    "$PACKAGE_DIR/debian/copyright" \
    "$PACKAGE_DIR/debian/install" \
    "$PACKAGE_DIR/debian/source/format" \
    "$PACKAGE_DIR/xdg/eczos-desktop-first-run.desktop"
chmod 0755 \
    "$PACKAGE_DIR/debian/rules" \
    "$PACKAGE_DIR/bin/eczos-theme-switch" \
    "$PACKAGE_DIR/bin/eczos-theme-toggle" \
    "$PACKAGE_DIR/lib/apply-desktop-defaults"

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)

PACKAGE_VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
PACKAGE_FILE="$OUTPUT_DIR/eczos-desktop-defaults_${PACKAGE_VERSION}_all.deb"
if [[ ! -f "$PACKAGE_FILE" ]]; then
    printf 'Expected package output is missing.\n' >&2
    exit 1
fi

install -m 0644 "$PACKAGE_FILE" "$TEMP_DIR/eczos-desktop-defaults.deb"
lintian "$TEMP_DIR/eczos-desktop-defaults.deb" || true
apt-get install -y "$TEMP_DIR/eczos-desktop-defaults.deb"
"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"

apt-get purge -y eczos-desktop-defaults
test ! -e /etc/xdg/autostart/eczos-desktop-first-run.desktop
test ! -e /usr/bin/eczos-theme-switch
test ! -e /usr/bin/eczos-theme-toggle
dpkg --audit
apt-get check

printf 'eczos-desktop-defaults lifecycle test passed\n'
