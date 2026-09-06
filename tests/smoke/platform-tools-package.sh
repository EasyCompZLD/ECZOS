#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-platform-tools | grep -Fx 'install ok installed'
for command in eczos-control-center eczos-doctor eczos-migrate eczos-support-report; do
    test -x "/usr/bin/$command"
    bash -n "/usr/bin/$command"
done
for desktop in ControlCenter Diagnostics Migration; do
    desktop-file-validate "/usr/share/applications/org.eczos.${desktop}.desktop"
done
/usr/bin/eczos-doctor --json | jq -e '.schemaVersion == 1 and .office == "waiting-for-vendor-permission"' >/dev/null
jq -e '.office.product == "SoftMaker FreeOffice 2024" and .office.redistributed == false' \
    /usr/share/eczos/product/default-apps.json >/dev/null
if /usr/bin/eczos-migrate --dry-run --source / >/dev/null 2>&1; then
    printf 'Migration assistant unexpectedly accepted root-owned execution or / as source.\n' >&2
    exit 1
fi
printf 'eczos-platform-tools installed-package smoke test passed\n'
