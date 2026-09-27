#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the Debian 13 test host.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} = debian && ${VERSION_CODENAME:-} = trixie ]] || {
    printf 'Debian 13 (trixie) is required.\n' >&2
    exit 1
}
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="$ROOT_DIR/packages/eczos-platform-core"
OUTPUT_DIR="$ROOT_DIR/packages"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules" "$PACKAGE_DIR/bin/"*
(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
version=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
package_file="$OUTPUT_DIR/eczos-platform-core_${version}_all.deb"
apt-get install -y "$package_file"
"$ROOT_DIR/tests/smoke/platform-core-package.sh"
apt-get purge -y eczos-platform-core
dpkg --audit
apt-get check
