#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || { printf 'Debian 13 (trixie) is required.\n' >&2; exit 1; }

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CORE_DIR="$ROOT_DIR/packages/eczos-platform-core"
TOOLS_DIR="$ROOT_DIR/packages/eczos-platform-tools"
CORE_VERSION=$(dpkg-parsechangelog -l"$CORE_DIR/debian/changelog" -S Version)
TOOLS_VERSION=$(dpkg-parsechangelog -l"$TOOLS_DIR/debian/changelog" -S Version)
CORE_DEB="$ROOT_DIR/packages/eczos-platform-core_${CORE_VERSION}_all.deb"
TOOLS_DEB="$ROOT_DIR/packages/eczos-platform-tools_${TOOLS_VERSION}_$(dpkg-architecture -qDEB_HOST_ARCH).deb"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends debhelper devscripts jq lintian cmake extra-cmake-modules \
    libkf6auth-dev libkf6config-dev libkf6coreaddons-dev libkf6kcmutils-dev \
    qt6-base-dev qt6-declarative-dev qt6-l10n-tools qt6-tools-dev
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/audit-package-architecture.sh"
for package_dir in "$CORE_DIR" "$TOOLS_DIR"; do
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm config; do
        [[ ! -f "$package_dir/debian/$maintainer_script" ]] || chmod 0755 "$package_dir/debian/$maintainer_script"
    done
    find "$package_dir/bin" -type f -exec chmod 0755 {} +
    [[ ! -d "$package_dir/lib" ]] || find "$package_dir/lib" -type f -exec chmod 0755 {} +
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
done
test -f "$CORE_DEB"; test -f "$TOOLS_DEB"
lintian "$CORE_DEB" "$TOOLS_DEB" || true
apt-get install -y "$CORE_DEB" "$TOOLS_DEB"
"$ROOT_DIR/tests/smoke/platform-core-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
/usr/bin/eczos-config-migrate check
/usr/bin/eczos-config-migrate status --json | jq -e '.schemaVersion == 1 and .healthy == true'
dpkg --audit
apt-get check

printf '\nECZOS package architecture and upgrade-safety batch passed.\n'
