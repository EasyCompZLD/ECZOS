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

for command in dpkg-buildpackage dpkg-parsechangelog jq; do
    command -v "$command" >/dev/null 2>&1 || {
        printf 'Missing build command: %s\n' "$command" >&2
        printf 'Run scripts/stage-windows-components-batch-vm.sh once to install all build dependencies.\n' >&2
        exit 69
    }
done

bash "$ROOT_DIR/scripts/verify-source.sh"
find "$PACKAGE_DIR/debian" -type f -exec chmod 0644 {} +
chmod 0755 "$PACKAGE_DIR/debian/rules"
find "$PACKAGE_DIR/bin" "$PACKAGE_DIR/lib" -type f -exec chmod 0755 {} + 2>/dev/null || true

(cd "$PACKAGE_DIR" && dpkg-buildpackage -us -uc -b)
version=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
deb="$ROOT_DIR/packages/eczos-windows-core_${version}_${architecture}.deb"
[[ -s "$deb" ]] || { printf 'Expected package was not built: %s\n' "$deb" >&2; exit 1; }

apt-get install -y "$deb"
bash "$ROOT_DIR/tests/smoke/windows-core-package.sh"

printf '\nECZ Windows X11 compatibility update passed.\n'
printf 'Package: %s\n' "$deb"
printf 'Classic cnc-ddraw games now show a safe Plasma X11 requirement before launch.\n'
