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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-gaming-core"
VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
DEB="$ROOT_DIR/packages/eczos-gaming-core_${VERSION}_amd64.deb"

find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules" "$PACKAGE_DIR/bin/eczos-gaming" \
    "$PACKAGE_DIR/lib/runtime-umu"
(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
test -f "$DEB"
apt-get install -y --no-install-recommends "$DEB"
"$ROOT_DIR/tests/smoke/gaming-core-package.sh"
/usr/bin/eczos-gaming doctor

printf '\nECZ Gaming diagnostic batch installed successfully.\n'
