#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="$ROOT_DIR/packages/eczos-platform-tools"
VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
DEB="$ROOT_DIR/packages/eczos-platform-tools_${VERSION}_${ARCH}.deb"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends cmake extra-cmake-modules libkf6auth-dev \
    libkf6config-dev libkf6coreaddons-dev libkf6kcmutils-dev qt6-base-dev \
    qt6-declarative-dev qt6-l10n-tools qt6-tools-dev systemd-timesyncd
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules"
find "$PACKAGE_DIR/bin" "$PACKAGE_DIR/lib" -type f -exec chmod 0755 {} +
find "$PACKAGE_DIR/applications" "$PACKAGE_DIR/polkit" "$PACKAGE_DIR/systemd" -type f -exec chmod 0644 {} +
(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
test -f "$DEB"
apt-get install -y "$DEB"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
/usr/bin/eczos-time status --json | tee /tmp/eczos-time-status.json | jq -e \
    '.schemaVersion == 1 and .timezone != "" and .provider != "none" and (.localRtc | type == "boolean")'

printf '\nECZOS time-reliability batch passed.\n'
printf 'The RTC local/UTC mode was inspected but never changed.\n'
