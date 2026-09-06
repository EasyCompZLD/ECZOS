#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

THEME_DIR=/usr/share/plymouth/themes/eczos
PLUGIN_DIR=$(plymouth --get-splash-plugin-path)

dpkg-query -W -f='${Status}\n' eczos-plymouth-theme | grep -Fx 'install ok installed'
test -s "$THEME_DIR/eczos.plymouth"
test -s "$THEME_DIR/eczos.script"
test -s "$THEME_DIR/logo.png"
grep -Fx 'ModuleName=script' "$THEME_DIR/eczos.plymouth"
test -s "$PLUGIN_DIR/script.so"
plymouth-set-default-theme --list | grep -Fx eczos
dpkg --audit
apt-get check

printf 'eczos-plymouth-theme installed-package smoke test passed\n'
