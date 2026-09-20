#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || exit 2
dpkg-query -W -f='${Status}\n' eczos-oobe | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-oobe
python3 - <<'PY'
compile(open('/usr/bin/eczos-oobe', encoding='utf-8').read(), '/usr/bin/eczos-oobe', 'exec')
PY
test -s /usr/share/eczos/oobe/Main.qml
test -s /usr/share/eczos/oobe/assets/ambient-loop.mp4
test -s /usr/share/eczos/oobe/assets/new-dawn.m4a
test -s /etc/xdg/autostart/org.eczos.OobeFirstRun.desktop
test -s /etc/xdg/autostart/org.kde.plasma-welcome.desktop
grep -Fx 'Hidden=true' /etc/xdg/autostart/org.kde.plasma-welcome.desktop
grep -Fx '    property bool musicEnabled: true' /usr/share/eczos/oobe/Main.qml
grep -Fx '    visibility: Window.FullScreen' /usr/share/eczos/oobe/Main.qml
grep -F 'qsTr("Turn music off")' /usr/share/eczos/oobe/Main.qml
grep -F 'branding/screenshots/settings.png' /usr/share/eczos/oobe/Main.qml
grep -F 'branding/screenshots/about-system.png' /usr/share/eczos/oobe/Main.qml
grep -F 'branding/screenshots/desktop-light.png' /usr/share/eczos/oobe/Main.qml
grep -F 'branding/screenshots/desktop-dark.png' /usr/share/eczos/oobe/Main.qml
for screenshot in browser-firefox browser-chrome browser-edge browser-konqueror \
    discover plasma-vaults steam-library-content; do
    grep -F "branding/screenshots/$screenshot.png" /usr/share/eczos/oobe/Main.qml
done
grep -F 'eczos-system-settings", ["--module", "kcm_networkmanagement"]' /usr/bin/eczos-oobe
for browser in 'Firefox' 'Google Chrome' 'Microsoft Edge through ECZ Windows' 'Konqueror'; do
    grep -F "$browser" /usr/share/eczos/oobe/Main.qml
done
for locale in nl de fr; do
    test -s "/usr/share/eczos/translations/eczos-oobe_${locale}.qm"
done
grep -F 'oobe-complete-v1' /usr/bin/eczos-oobe
grep -F 'browser-choice' /usr/bin/eczos-oobe
grep -F 'X-KDE-autostart-after=panel' /etc/xdg/autostart/org.eczos.OobeFirstRun.desktop
if dpkg-query -W -f='${Status}\n' plasma-welcome 2>/dev/null | grep -Fxq 'install ok installed'; then
    printf 'Plasma Welcome must not compete with the ECZOS OOBE.\n' >&2
    exit 1
fi
dpkg --audit
apt-get check
printf 'eczos-oobe installed-package smoke test passed\n'
