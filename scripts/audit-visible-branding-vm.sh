#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

REPORT=/var/log/eczos-visible-branding-audit.txt
TEMP_REPORT=$(mktemp /tmp/eczos-branding-audit.XXXXXX)
trap 'rm -f "$TEMP_REPORT"' EXIT

{
    printf 'ECZOS visible branding audit\nGenerated: %s\n\n' "$(date --iso-8601=seconds)"
    printf '[Product identity]\n'
    eczos-info 2>&1 || true
    printf '\n[Boot and login selection]\n'
    plymouth-set-default-theme 2>&1 || true
    grep -RHE '^[[:space:]]*(Current|Theme)=' /etc/sddm.conf /etc/sddm.conf.d 2>/dev/null || true
    grep -E '^(GRUB_DISTRIBUTOR|GRUB_BACKGROUND)=' /etc/default/grub 2>/dev/null || true
    printf '\n[Console-visible Debian strings]\n'
    grep -HniE 'Debian|KDE' /etc/issue /etc/issue.net /etc/motd 2>/dev/null || true
    printf '\n[Graphical launcher-visible Debian or KDE strings]\n'
    grep -RHE '^(Name|GenericName|Comment)=.*(Debian|KDE)' /usr/share/applications 2>/dev/null || true
    printf '\n[ECZOS package-owned visible Debian or KDE strings]\n'
    grep -RHEi 'Debian|KDE' /usr/share/eczos /usr/share/applications/org.eczos.*.desktop \
        /usr/share/sddm/themes/eczos /usr/share/plymouth/themes/eczos 2>/dev/null || true
} >"$TEMP_REPORT"

install -m 0600 "$TEMP_REPORT" "$REPORT"
printf 'Branding audit written to %s\n' "$REPORT"
cat "$REPORT"

