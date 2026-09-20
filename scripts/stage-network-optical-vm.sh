#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || exit 2
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export DEBIAN_FRONTEND=noninteractive

"$ROOT_DIR/scripts/verify-source.sh"
apt-get update
apt-get install -y avahi-daemon avahi-utils eject iproute2 lsscsi open-iscsi \
    pkexec polkitd psmisc python3-rtslib-fb sg3-utils targetcli-fb udev udisks2
"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"
"$ROOT_DIR/scripts/prepare-image-packages-vm.sh"
apt-get install -y "$ROOT_DIR"/image/config/packages.chroot/eczos-*.deb

"$ROOT_DIR/tests/smoke/network-optical-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
printf 'Network optical drive development batch installed successfully.\n'
