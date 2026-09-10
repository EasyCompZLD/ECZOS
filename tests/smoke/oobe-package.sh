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
grep -Fx '    property bool musicEnabled: true' /usr/share/eczos/oobe/Main.qml
grep -F 'Muziek uitzetten' /usr/share/eczos/oobe/Main.qml
grep -F 'oobe-complete-v1' /usr/bin/eczos-oobe
dpkg --audit
apt-get check
printf 'eczos-oobe installed-package smoke test passed\n'
