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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-platform-tools"
VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
ARCH=$(dpkg-architecture -qDEB_HOST_ARCH)
DEB="$ROOT_DIR/packages/eczos-platform-tools_${VERSION}_${ARCH}.deb"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    cmake extra-cmake-modules libkf6auth-dev libkf6config-dev \
    libkf6coreaddons-dev libkf6kcmutils-dev qt6-base-dev qt6-declarative-dev \
    qt6-l10n-tools qt6-tools-dev

"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules"
find "$PACKAGE_DIR/bin" -type f -exec chmod 0755 {} +
find "$PACKAGE_DIR/applications" "$PACKAGE_DIR/systemd" -type f -exec chmod 0644 {} +

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
test -f "$DEB"
apt-get install -y "$DEB"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"

desktop_user=${ECZOS_DESKTOP_USER:-ecz}
if id "$desktop_user" >/dev/null 2>&1 && [[ -S "/run/user/$(id -u "$desktop_user")/bus" ]]; then
    desktop_uid=$(id -u "$desktop_user")
    runuser -u "$desktop_user" -- env \
        XDG_RUNTIME_DIR="/run/user/$desktop_uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$desktop_uid/bus" \
        /usr/bin/eczos-remote-input adopt
    runuser -u "$desktop_user" -- env \
        XDG_RUNTIME_DIR="/run/user/$desktop_uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$desktop_uid/bus" \
        /usr/bin/eczos-remote-input status --json | jq -e \
            '.schemaVersion == 1 and .managed == true and .enabled == true and .duplicate == false'
else
    printf 'Package installed; no active %s desktop session was found, so adoption was not started.\n' "$desktop_user"
fi

printf '\nECZOS Remote Input batch passed.\n'
printf 'Open ECZOS Settings > Keyboard and mouse sharing for the visual check.\n'
