#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root inside a disposable Debian 13 development VM.\n' >&2
    exit 2
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Cannot identify this operating system.\n' >&2
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to modify this host: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    debhelper \
    devscripts \
    git \
    lintian \
    rsync \
    shellcheck

printf 'ECZOS Debian 13 package-development environment is ready.\n'
