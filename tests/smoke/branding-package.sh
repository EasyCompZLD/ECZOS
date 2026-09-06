#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root inside the disposable test VM.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-branding | grep -Fx 'install ok installed'

for asset in \
    /usr/share/eczos/branding/login/login-bg.png \
    /usr/share/eczos/branding/login/login-logo.png \
    /usr/share/eczos/branding/logo/logo.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper-dark.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper-light.png; do
    test -s "$asset"
done

dpkg --audit
apt-get check

printf 'eczos-branding installed-package smoke test passed\n'
