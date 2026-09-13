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
    cmake \
    debhelper \
    devscripts \
    dosfstools \
    git \
    extra-cmake-modules \
    grub-efi-amd64-bin \
    grub-pc-bin \
    intel-microcode \
    isolinux \
    live-build \
    libkf6auth-dev \
    libkf6config-dev \
    libkf6coreaddons-dev \
    libkf6kcmutils-dev \
    lintian \
    mtools \
    rsync \
    qt6-base-dev \
    qt6-declarative-dev \
    shellcheck \
    squashfs-tools \
    syslinux-common \
    xorriso

printf 'ECZOS Debian 13 package and image development environment is ready.\n'
printf 'Reboot the host if intel-microcode was newly installed.\n'
