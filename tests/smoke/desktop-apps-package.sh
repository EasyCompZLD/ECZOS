#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-desktop-apps | grep -Fx 'install ok installed'
for package in firefox-esr thunderbird vlc plasma-discover flatpak kdeconnect kup-backup fwupd cups skanpage gamemode mangohud steam-installer steam-devices; do
    dpkg-query -W -f='${Status}\n' "$package" | grep -Fx 'install ok installed'
done
if dpkg-query -W -f='${Status}\n' libreoffice-common 2>/dev/null | grep -Fxq 'install ok installed'; then
    printf 'LibreOffice must not be part of the ECZOS application profile.\n' >&2
    exit 1
fi
printf 'eczos-desktop-apps installed-package smoke test passed\n'
