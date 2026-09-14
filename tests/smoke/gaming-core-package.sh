#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-gaming-core | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-gaming
test -x /usr/lib/eczos/gaming/runtime-umu
test -x /usr/lib/eczos/gaming/repair-runtime
test -r /usr/share/polkit-1/actions/org.eczos.gaming.policy
test -r /usr/share/applications/org.eczos.Gaming.desktop
test -r /usr/share/eczos/gaming/runtime-definitions/umu-launcher-1.4.0.json
bash -n /usr/bin/eczos-gaming
bash -n /usr/lib/eczos/gaming/runtime-umu
bash -n /usr/lib/eczos/gaming/repair-runtime
jq -e '.version == "1.4.0-1" and (.sha256 | length == 64)' \
    /usr/share/eczos/gaming/runtime-definitions/umu-launcher-1.4.0.json >/dev/null
/usr/bin/eczos-gaming doctor --json | jq -e '
    .schemaVersion == 1 and
    (.verdict == "ready" or .verdict == "setup-required" or .verdict == "unsupported") and
    (.vulkan.hardware | type == "boolean") and
    (.runtime.umu | type == "boolean")' >/dev/null
grep -F 'Name=ECZ Gaming' /usr/share/applications/org.eczos.Gaming.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:gaming' /usr/share/applications/org.eczos.Gaming.desktop
grep -F 'PROTONPATH=UMU-Proton' /usr/lib/eczos/gaming/runtime-umu
grep -F 'Start games niet als root.' /usr/lib/eczos/gaming/runtime-umu
grep -F 'sha256sum --check --strict --status' /usr/lib/eczos/gaming/repair-runtime
grep -F 'org.eczos.gaming.repair' /usr/share/polkit-1/actions/org.eczos.gaming.policy

printf 'eczos-gaming-core installed-package smoke test passed\n'
