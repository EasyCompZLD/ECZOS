#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-platform-tools | grep -Fx 'install ok installed'
for command in eczos-control-center eczos-doctor eczos-migrate eczos-support-report; do
    test -x "/usr/bin/$command"
    bash -n "/usr/bin/$command"
done
test -x /usr/bin/eczos-ui
test -x /usr/bin/eczos-system-settings
# QStringLiteral stores this value as little-endian UTF-16 in the native
# executable, so inspect that encoding instead of treating the binary as text.
strings -a -el /usr/bin/eczos-system-settings | grep -Fx 'eczos-system-settings.sock' >/dev/null
test -x /usr/bin/systemsettings
test -x /usr/bin/kcmshell6
test -x /usr/bin/systemsettings.eczos-distrib
test -x /usr/bin/kcmshell6.eczos-distrib
test "$(dpkg-divert --listpackage /usr/bin/systemsettings)" = eczos-platform-tools
test "$(dpkg-divert --listpackage /usr/bin/kcmshell6)" = eczos-platform-tools
grep -F 'exec /usr/bin/eczos-system-settings --module "$argument"' /usr/bin/systemsettings
grep -F 'exec /usr/bin/eczos-system-settings --module "$argument"' /usr/bin/kcmshell6
grep -F 'exec /usr/bin/kcmshell6.eczos-distrib "$@"' /usr/bin/kcmshell6
grep -F 'exec /usr/bin/eczos-system-settings "$@"' /usr/bin/eczos-control-center
test -r /usr/share/eczos/ui/Main.qml
for locale in nl de fr; do
    test -s "/usr/share/eczos/translations/eczos-system-settings_${locale}.qm"
done
python3 - /usr/bin/eczos-ui <<'PY'
import pathlib
import sys
compile(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), sys.argv[1], "exec")
PY
for desktop in ControlCenter Diagnostics Migration; do
    desktop-file-validate "/usr/share/applications/org.eczos.${desktop}.desktop"
done
grep -Fx 'Exec=eczos-system-settings' /usr/share/applications/org.eczos.ControlCenter.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:diagnostics' /usr/share/applications/org.eczos.Diagnostics.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:migration' /usr/share/applications/org.eczos.Migration.desktop
grep -F 'os.execv(str(native_host), [str(native_host), "--module", native_page])' /usr/bin/eczos-ui
/usr/bin/eczos-ui --list-kcms-json | jq -e '.schemaVersion == 1 and (.modules | type == "array") and (.modules | length > 10)' >/dev/null
QT_QPA_PLATFORM=offscreen /usr/bin/eczos-system-settings --list-json | jq -e '
    .schemaVersion == 1 and (.eczosPages | length == 7) and
    ([.eczosPages[].id] | contains(["eczos:overview", "eczos:windows", "eczos:gaming", "eczos:recovery", "eczos:migration", "eczos:diagnostics", "eczos:support"])) and
    (.modules | length >= 80) and
    ([.modules[].id] | contains(["kcm_users", "kcm_networkmanagement", "kcm_kscreen", "kcm_printer_manager", "kcm_updates"]))
' >/dev/null
/usr/bin/eczos-doctor --json | jq -e '.schemaVersion == 1 and .office == "installed"' >/dev/null
jq -e '.office.product == "SoftMaker FreeOffice 2024" and .office.package == "softmaker-freeoffice-2024" and .office.redistributed == true' \
    /usr/share/eczos/product/default-apps.json >/dev/null
if /usr/bin/eczos-migrate --dry-run --source / >/dev/null 2>&1; then
    printf 'Migration assistant unexpectedly accepted root-owned execution or / as source.\n' >&2
    exit 1
fi
printf 'eczos-platform-tools installed-package smoke test passed\n'
