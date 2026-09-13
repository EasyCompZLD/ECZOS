#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-desktop-defaults | grep -Fx 'install ok installed'
for file in \
    /usr/bin/eczos-theme-switch \
    /usr/bin/eczos-theme-toggle \
    /usr/lib/eczos/apply-desktop-defaults; do
    test -x "$file"
    bash -n "$file"
done
test -s /etc/xdg/autostart/eczos-desktop-first-run.desktop
test -s /etc/xdg/ksplashrc
test -s /etc/skel/.config/ksplashrc
grep -Fx 'Theme=org.eczos.desktop' /etc/xdg/ksplashrc
grep -Fx 'Theme=org.eczos.desktop' /etc/skel/.config/ksplashrc
grep -Fx 'OnlyShowIn=KDE;' /etc/xdg/autostart/eczos-desktop-first-run.desktop
grep -F 'START_ICON=file:///usr/share/eczos/branding/logo/logo-dark.png' /usr/bin/eczos-theme-switch
grep -F 'START_ICON=file:///usr/share/eczos/branding/logo/logo.png' /usr/bin/eczos-theme-switch
grep -F 'desktop-defaults-v5' /usr/lib/eczos/apply-desktop-defaults
grep -F 'timeout 12s plasma-apply-wallpaperimage' /usr/bin/eczos-theme-switch
grep -F 'kscreenlockerrc' /usr/bin/eczos-theme-switch
grep -F 'org.eczos.desktop' /usr/bin/eczos-theme-switch
test -s /usr/share/plasma/look-and-feel/org.eczos.desktop/metadata.json
test -s /usr/share/plasma/look-and-feel/org.eczos.desktop/contents/splash/Splash.qml
test -s /usr/share/plasma/look-and-feel/org.eczos.desktop/contents/splash/eczos-startup.mp4
for wallpaper in \
    eczoswallpaper.png \
    eczoswallpaper-light.png \
    eczoswallpaper-dark.png; do
    test -r "/usr/share/eczos/branding/wallpapers/$wallpaper"
done
dpkg --audit
apt-get check

printf 'eczos-desktop-defaults installed-package smoke test passed\n'
