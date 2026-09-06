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
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-sddm-preview.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

BRANDING_PACKAGE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    -name 'eczos-branding_*_all.deb' -print -quit)
THEME_PACKAGE=$(find "$OUTPUT_DIR" -maxdepth 1 -type f \
    -name 'eczos-sddm-theme_*_all.deb' -print -quit)

if [[ -z "$BRANDING_PACKAGE" || -z "$THEME_PACKAGE" ]]; then
    printf 'Package output is missing. Run test-sddm-theme-package-vm.sh first.\n' >&2
    exit 1
fi

install -m 0644 "$BRANDING_PACKAGE" "$TEMP_DIR/eczos-branding.deb"
install -m 0644 "$THEME_PACKAGE" "$TEMP_DIR/eczos-sddm-theme.deb"

apt-get install -y "$TEMP_DIR/eczos-branding.deb" "$TEMP_DIR/eczos-sddm-theme.deb"
"$ROOT_DIR/tests/smoke/sddm-theme-package.sh"

printf '\nECZOS SDDM preview is installed and will remain installed.\n'
printf 'Reboot the test machine to inspect the login screen.\n'
printf 'Rollback: apt-get purge -y eczos-sddm-theme eczos-branding\n'
