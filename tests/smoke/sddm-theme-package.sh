#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-sddm-theme | grep -Fx 'install ok installed'
grep -Fx 'Current=eczos' /etc/sddm.conf.d/90-eczos-theme.conf

for file in metadata.desktop theme.conf; do
    test -s "/usr/share/sddm/themes/eczos/$file"
done

for link in \
    Background.qml \
    KeyboardButton.qml \
    Login.qml \
    Main.qml \
    SessionButton.qml \
    default-logo.svg \
    faces/.face.icon \
    preview.png; do
    test -L "/usr/share/sddm/themes/eczos/$link"
    test -e "/usr/share/sddm/themes/eczos/$link"
done

runuser -u sddm -- test -r /usr/share/eczos/branding/login/login-bg.png
runuser -u sddm -- test -r /usr/share/eczos/branding/login/login-logo.png
runuser -u sddm -- test -r /usr/share/sddm/themes/eczos/Main.qml

systemctl is-enabled sddm
systemctl is-active sddm
dpkg --audit
apt-get check

printf 'eczos-sddm-theme installed-package smoke test passed\n'
