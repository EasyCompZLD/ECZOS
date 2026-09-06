#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

for package in \
    eczos-desktop \
    eczos-release \
    eczos-branding \
    eczos-desktop-defaults \
    eczos-plymouth-theme \
    eczos-sddm-theme; do
    dpkg-query -W -f='${Status}\n' "$package" | grep -Fx 'install ok installed'
done
dpkg --audit
apt-get check

printf 'eczos-desktop metapackage smoke test passed\n'
