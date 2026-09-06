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
PACKAGE_DIR="$ROOT_DIR/packages/eczos-plymouth-theme"
STATE_DIR=/var/lib/eczos/preview
PREVIOUS_THEME_FILE="$STATE_DIR/plymouth-theme.previous"
GRUB_DROPIN=/etc/default/grub.d/90-eczos-plymouth-preview.cfg
TEMP_DIR=$(mktemp -d /tmp/eczos-plymouth-preview.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

PACKAGE_VERSION=$(dpkg-parsechangelog -l"$PACKAGE_DIR/debian/changelog" -S Version)
PACKAGE_FILE="$OUTPUT_DIR/eczos-plymouth-theme_${PACKAGE_VERSION}_all.deb"
if [[ ! -f "$PACKAGE_FILE" ]]; then
    printf 'Package output is missing. Run test-plymouth-theme-package-vm.sh first.\n' >&2
    exit 1
fi

install -m 0644 "$PACKAGE_FILE" "$TEMP_DIR/eczos-plymouth-theme.deb"
apt-get install -y "$TEMP_DIR/eczos-plymouth-theme.deb"
"$ROOT_DIR/tests/smoke/plymouth-theme-package.sh"

mkdir -p "$STATE_DIR" /etc/default/grub.d
if [[ ! -e "$PREVIOUS_THEME_FILE" ]]; then
    plymouth-set-default-theme > "$PREVIOUS_THEME_FILE"
    chmod 0644 "$PREVIOUS_THEME_FILE"
fi

cat > "$GRUB_DROPIN" <<'EOF'
case " $GRUB_CMDLINE_LINUX_DEFAULT " in
    *" splash "*) ;;
    *) GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT splash" ;;
esac
EOF
chmod 0644 "$GRUB_DROPIN"

plymouth-set-default-theme --rebuild-initrd eczos
update-grub

printf '\nECZOS Plymouth preview is installed and selected.\n'
printf 'Reboot the test machine to inspect the boot screen.\n'
printf 'Rollback with: %s/scripts/remove-plymouth-theme-preview.sh\n' "$ROOT_DIR"
