#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2
    exit 2
fi
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="$ROOT_DIR/packages/eczos-windows-core"
VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
DEB="$ROOT_DIR/packages/eczos-windows-core_${VERSION}_amd64.deb"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential debhelper devscripts dpkg-dev lintian
bash "$ROOT_DIR/scripts/verify-source.sh"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules" "$PACKAGE_DIR/bin/eczos-windows" "$PACKAGE_DIR/lib/runtime-wine-system"
(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
apt-get install -y "$DEB"
bash "$ROOT_DIR/tests/smoke/windows-core-package.sh"

printf '\nECZ Windows entry-point hotfix %s passed.\n' "$VERSION"
printf 'Use “Search again” for an existing installation; reinstalling is not required.\n'
