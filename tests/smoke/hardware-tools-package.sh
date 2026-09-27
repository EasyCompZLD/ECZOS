#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-hardware-tools | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-hardware
test -x /usr/lib/eczos/hardware/apply-profile
test -x /usr/lib/eczos/hardware/repair-issue
test -r /usr/share/polkit-1/actions/org.eczos.hardware.policy
grep -F '/usr/lib/eczos/hardware/repair-issue' /usr/share/polkit-1/actions/org.eczos.hardware.policy >/dev/null
python3 -m py_compile /usr/bin/eczos-hardware
bash -n /usr/lib/eczos/hardware/apply-profile
bash -n /usr/lib/eczos/hardware/repair-issue
/usr/bin/eczos-hardware status --json | jq -e '
    .schemaVersion == 2 and (.cpu.logicalProcessors | type == "number") and
    (.memory.totalKiB | type == "number") and (.memory.swapKiB | type == "number") and
    (.memory.zramActive | type == "boolean") and
    (.recommendedProfile | IN("lightweight","standard","performance","gaming","enterprise")) and
    (.profiles | keys | length == 5) and (.issues | type == "array") and
    (.graphicsDetails | type == "array") and
    (all(.issues[]; (.repairable | type == "boolean") and (.repair | type == "string"))) and
    (.health == "ready" or .health == "degraded")
' >/dev/null
/usr/bin/eczos-hardware profiles | jq -e '.lightweight.swappiness == 100 and .gaming.priority == 140' >/dev/null
printf 'eczos-hardware-tools installed-package smoke test passed\n'
