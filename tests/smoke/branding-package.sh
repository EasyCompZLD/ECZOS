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
    /usr/share/eczos/branding/logo/logo-dark.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper-dark.png \
    /usr/share/eczos/branding/wallpapers/eczoswallpaper-light.png; do
    test -s "$asset"
done

for link in \
    /usr/share/icons/hicolor/512x512/apps/eczos-start.png \
    /usr/share/icons/hicolor/512x512/apps/eczos-start-light.png \
    /usr/share/icons/hicolor/512x512/apps/eczos-start-dark.png \
    /usr/share/pixmaps/eczos-start.png; do
    test -L "$link"
    test -e "$link"
done

test -s /etc/default/grub.d/zz-eczos-grub.cfg
grep -Fx 'GRUB_DISTRIBUTOR="ECZOS"' /etc/default/grub.d/zz-eczos-grub.cfg
grep -Fx 'GRUB_BACKGROUND="/usr/share/eczos/branding/wallpapers/eczoswallpaper-dark.png"' \
    /etc/default/grub.d/zz-eczos-grub.cfg
grep -Fx 'GRUB_TERMINAL_OUTPUT="gfxterm"' /etc/default/grub.d/zz-eczos-grub.cfg

dpkg --audit
apt-get check

printf 'eczos-branding installed-package smoke test passed\n'
