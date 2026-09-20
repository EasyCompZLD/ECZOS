#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-recovery-media | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-recovery-media
test -x /usr/lib/eczos-recovery-media/write-media
bash -n /usr/bin/eczos-recovery-media
bash -n /usr/lib/eczos-recovery-media/write-media
desktop-file-validate /usr/share/applications/org.eczos.RecoveryMedia.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:recovery' /usr/share/applications/org.eczos.RecoveryMedia.desktop
if grep -Fq 'konsole --hold' /usr/bin/eczos-recovery-media; then
    printf 'Recovery media creator still launches a terminal.\n' >&2
    exit 1
fi
grep -Fq -- '--json-progress' /usr/lib/eczos-recovery-media/write-media
grep -Fxq 'CatalogURL=https://repo.easycomp.cloud/eczos/releases.json' /etc/eczos/recovery-media.conf
printf 'eczos-recovery-media installed-package smoke test passed\n'
