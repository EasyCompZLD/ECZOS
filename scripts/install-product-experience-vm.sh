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
"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"
install -m 0644 "$ROOT_DIR/config/debian-extra-components.list" \
    /etc/apt/sources.list.d/eczos-extra-components.list
mapfile -t libreoffice_packages < <(dpkg-query -W -f='${binary:Package} ${db:Status-Abbrev}\n' 'libreoffice*' 2>/dev/null \
    | awk '$2 == "ii" {print $1}' || true)
if (( ${#libreoffice_packages[@]} )); then
    apt-get purge -y "${libreoffice_packages[@]}"
fi

dpkg --add-architecture i386
apt-get update
apt-get install -y \
    ark cups dolphin-plugins filelight firefox-esr flatpak \
    fonts-crosextra-caladea fonts-crosextra-carlito fonts-liberation \
    fwupd gamemode gwenview kde-spectacle kdeconnect kio-admin kio-extras \
    kup-backup mangohud mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
    okular packagekit partitionmanager plasma-discover \
    plasma-discover-backend-flatpak plasma-discover-backend-fwupd \
    printer-driver-all skanpage steam-devices steam-installer \
    system-config-printer thunderbird vlc

flatpak remote-add --system --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
"$ROOT_DIR/scripts/stage-platform-batch-vm.sh"

printf '\nECZOS product experience installed. Log out and back in once.\n'
printf 'FreeOffice is installed and updated through the signed SoftMaker repository.\n'
