#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-boot-tools | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-boot
test -x /usr/lib/eczos/boot/helper
test -r /usr/share/polkit-1/actions/org.eczos.boot.policy
test -r /usr/lib/systemd/system/eczos-boot-scan.service
python3 -m py_compile /usr/bin/eczos-boot /usr/lib/eczos/boot/helper
/usr/lib/eczos/boot/helper scan >/tmp/eczos-boot-inventory.json
jq -e '.schemaVersion == 1 and (.mode == "uefi" or .mode == "bios") and
    (.operatingSystems | type == "array") and (.firmwareEntries | type == "array") and
    .policy.changesBootOrder == false and .policy.reinstallsBootloader == false' /tmp/eczos-boot-inventory.json >/dev/null
/usr/bin/eczos-boot status --json | jq -e '.schemaVersion == 1 and .stale == false' >/dev/null
grep -F 'ExecStart=/usr/lib/eczos/boot/helper scan' /usr/lib/systemd/system/eczos-boot-scan.service >/dev/null
printf 'eczos-boot-tools installed-package smoke test passed\n'
