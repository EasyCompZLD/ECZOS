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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-installer"
VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
DEB="$ROOT_DIR/packages/eczos-installer_${VERSION}_all.deb"

export DEBIAN_FRONTEND=noninteractive
bash "$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
bash "$ROOT_DIR/scripts/verify-source.sh"

find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules"
for maintainer_script in preinst postinst prerm postrm config; do
    if [[ -f "$PACKAGE_DIR/debian/$maintainer_script" ]]; then
        chmod 0755 "$PACKAGE_DIR/debian/$maintainer_script"
    fi
done
find "$PACKAGE_DIR/bin" -type f -exec chmod 0755 {} +
find "$PACKAGE_DIR/applications" "$PACKAGE_DIR/branding" "$PACKAGE_DIR/config" "$PACKAGE_DIR/i18n" "$PACKAGE_DIR/xdg" \
    -type f -exec chmod 0644 {} +

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
apt-get install -y "$DEB"
bash "$ROOT_DIR/tests/smoke/installer-package.sh"
install -m 0644 "$DEB" "$ROOT_DIR/image/config/packages.chroot/$(basename "$DEB")"

printf 'ECZOS installer branding package %s installed, verified and staged.\n' "$VERSION"
