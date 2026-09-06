#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root inside a disposable Debian 13 test VM.\n' >&2
    exit 2
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Cannot identify this operating system.\n' >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE_DIR="$ROOT_DIR/packages/eczos-branding"
OUTPUT_DIR="$ROOT_DIR/packages"

cd "$PACKAGE_DIR"
dpkg-buildpackage -us -uc -b

PACKAGE_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    -name 'eczos-branding_*_all.deb' -print -quit)

if [[ -z "$PACKAGE_FILE" ]]; then
    printf 'Package build completed without producing an expected .deb file.\n' >&2
    exit 1
fi

lintian "$PACKAGE_FILE" || true
apt-get install -y "$PACKAGE_FILE"
"$ROOT_DIR/tests/smoke/branding-package.sh"

apt-get purge -y eczos-branding

if [[ -e /usr/share/eczos/branding ]]; then
    printf 'Branding payload remains after package purge.\n' >&2
    exit 1
fi

dpkg --audit
apt-get check

printf 'eczos-branding lifecycle test passed\n'
