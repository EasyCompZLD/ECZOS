#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLYMOUTH_DIR="$ROOT_DIR/packages/eczos-plymouth-theme"
DEFAULTS_DIR="$ROOT_DIR/packages/eczos-desktop-defaults"
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-next-preview.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

normalize_package() {
    local package_dir=$1
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm; do
        if [[ -f "$package_dir/debian/$maintainer_script" ]]; then
            chmod 0755 "$package_dir/debian/$maintainer_script"
        fi
    done
}

normalize_package "$PLYMOUTH_DIR"
normalize_package "$DEFAULTS_DIR"
find "$PLYMOUTH_DIR/theme" -type f -exec chmod 0644 {} +
chmod 0644 "$DEFAULTS_DIR/xdg/eczos-desktop-first-run.desktop"
chmod 0755 "$DEFAULTS_DIR/bin/"* "$DEFAULTS_DIR/lib/"*

(cd "$PLYMOUTH_DIR" && dpkg-buildpackage -us -uc -b)
(cd "$DEFAULTS_DIR" && dpkg-buildpackage -us -uc -b)

PLYMOUTH_VERSION=$(dpkg-parsechangelog -l"$PLYMOUTH_DIR/debian/changelog" -S Version)
DEFAULTS_VERSION=$(dpkg-parsechangelog -l"$DEFAULTS_DIR/debian/changelog" -S Version)
PLYMOUTH_PACKAGE="$OUTPUT_DIR/eczos-plymouth-theme_${PLYMOUTH_VERSION}_all.deb"
DEFAULTS_PACKAGE="$OUTPUT_DIR/eczos-desktop-defaults_${DEFAULTS_VERSION}_all.deb"
test -f "$PLYMOUTH_PACKAGE"
test -f "$DEFAULTS_PACKAGE"

install -m 0644 "$PLYMOUTH_PACKAGE" "$TEMP_DIR/eczos-plymouth-theme.deb"
install -m 0644 "$DEFAULTS_PACKAGE" "$TEMP_DIR/eczos-desktop-defaults.deb"
lintian "$TEMP_DIR/eczos-plymouth-theme.deb" "$TEMP_DIR/eczos-desktop-defaults.deb" || true
apt-get install -y "$TEMP_DIR/eczos-plymouth-theme.deb" "$TEMP_DIR/eczos-desktop-defaults.deb"
"$ROOT_DIR/tests/smoke/plymouth-theme-package.sh"
"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"

"$ROOT_DIR/scripts/install-plymouth-theme-preview.sh"

printf '\nNext ECZOS preview batch is staged:\n'
printf '  - original animated Plymouth theme;\n'
printf '  - one-time Plasma ECZOS appearance defaults;\n'
printf '  - existing SDDM theme remains installed.\n'
printf 'Reboot to test both visual changes.\n'
