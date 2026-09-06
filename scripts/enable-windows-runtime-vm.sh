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

if ! dpkg --print-foreign-architectures | grep -Fx i386 >/dev/null; then
    dpkg --add-architecture i386
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wine32:i386
dpkg-query -W -f='${Status}\n' wine32:i386 | grep -Fx 'install ok installed'

printf 'ECZ Windows 32-bit and 64-bit runtime support is ready.\n'
