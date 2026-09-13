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
grep -Fx 'ModuleName=two-step' "$THEME_DIR/eczos.plymouth"
test -s "$PLUGIN_DIR/two-step.so"
test "$(find "$THEME_DIR/images" -maxdepth 1 -type f -name 'animation-*.png' | wc -l)" -eq 12
test "$(find "$THEME_DIR/images" -maxdepth 1 -type f -name 'throbber-*.png' | wc -l)" -eq 12
for frame in $(seq 0 11); do
    test -s "$THEME_DIR/images/animation-$frame.png"
    test -s "$THEME_DIR/images/throbber-$frame.png"
done
for image in watermark.png bgrt-fallback.png logo.png; do
    test -s "$THEME_DIR/images/$image"
done
for image in bullet.png capslock.png entry.png keyboard.png keymap-render.png lock.png; do
    test -s "$THEME_DIR/images/$image"
done
plymouth-set-default-theme --list | grep -Fx eczos
dpkg --audit
apt-get check

printf 'eczos-plymouth-theme installed-package smoke test passed\n'
