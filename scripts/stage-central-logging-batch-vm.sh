#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE=eczos-platform-tools
PACKAGE_DIR="$ROOT_DIR/packages/$PACKAGE"
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends debhelper devscripts lintian jq \
    cmake extra-cmake-modules libkf6auth-dev libkf6config-dev libkf6coreaddons-dev \
    libkf6kcmutils-dev qt6-base-dev qt6-declarative-dev qt6-l10n-tools qt6-tools-dev

"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/audit-package-architecture.sh"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules"
for maintainer in preinst postinst prerm postrm; do
    [[ ! -f "$PACKAGE_DIR/debian/$maintainer" ]] || chmod 0755 "$PACKAGE_DIR/debian/$maintainer"
done
for executable_dir in bin lib; do
    [[ ! -d "$PACKAGE_DIR/$executable_dir" ]] || find "$PACKAGE_DIR/$executable_dir" -type f -exec chmod 0755 {} +
done

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
version=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
arch=$(dpkg-architecture -qDEB_HOST_ARCH)
deb="$ROOT_DIR/packages/${PACKAGE}_${version}_${arch}.deb"
test -f "$deb"
lintian "$deb" || true
apt-get install -y "$deb"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"

printf '\nECZOS central logging and support-sharing batch passed.\n'
printf 'Open ECZOS Settings > Support to test Save, Email and GitHub. Nothing is sent automatically.\n'
