#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

STATE_DIR=/var/lib/eczos/preview
PREVIOUS_THEME_FILE="$STATE_DIR/plymouth-theme.previous"
GRUB_DROPIN=/etc/default/grub.d/90-eczos-plymouth-preview.cfg

if [[ -s "$PREVIOUS_THEME_FILE" ]]; then
    PREVIOUS_THEME=$(cat "$PREVIOUS_THEME_FILE")
    if [[ -s "/usr/share/plymouth/themes/$PREVIOUS_THEME/$PREVIOUS_THEME.plymouth" ]]; then
        plymouth-set-default-theme "$PREVIOUS_THEME"
    else
        plymouth-set-default-theme --reset
    fi
else
    plymouth-set-default-theme --reset
fi

rm -f "$GRUB_DROPIN" "$PREVIOUS_THEME_FILE"
apt-get purge -y eczos-plymouth-theme
update-initramfs -u
update-grub
rmdir "$STATE_DIR" /var/lib/eczos 2>/dev/null || true

printf 'ECZOS Plymouth preview was removed and the prior theme was restored.\n'
