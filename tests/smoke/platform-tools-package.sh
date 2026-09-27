#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-platform-tools | grep -Fx 'install ok installed'
for component in eczos-boot-tools eczos-hardware-tools eczos-network-shares; do
    dpkg-query -W -f='${Status}\n' "$component" | grep -Fx 'install ok installed'
done
dpkg --compare-versions "$(dpkg-query -W -f='${Version}' eczos-boot-tools)" ge 0.1.0
dpkg --compare-versions "$(dpkg-query -W -f='${Version}' eczos-hardware-tools)" ge 0.1.0
dpkg --compare-versions "$(dpkg-query -W -f='${Version}' eczos-network-shares)" ge 0.1.0
for command in eczos-control-center eczos-doctor eczos-migrate eczos-support-report eczos-remote-input eczos-time; do
    test -x "/usr/bin/$command"
    bash -n "/usr/bin/$command"
done
test -x /usr/bin/eczos-logs
python3 - /usr/bin/eczos-logs <<'PY'
import pathlib
import sys
compile(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), sys.argv[1], "exec")
PY
/usr/bin/eczos-logs summary --days 1 | jq -e '.schemaVersion == 1 and (.total | type == "number") and (.modules | type == "array")' >/dev/null
filtered=$(printf 'password=visible user@example.com /home/person/file 192.168.1.20 aa:bb:cc:dd:ee:ff\n' | /usr/bin/eczos-logs sanitize)
for secret in visible user@example.com /home/person 192.168.1.20 aa:bb:cc:dd:ee:ff; do
    [[ $filtered != *"$secret"* ]]
done
test -x /usr/lib/eczos-platform-tools/remote-support-guard
python3 -m py_compile /usr/lib/eczos-platform-tools/remote-support-guard
test -r /usr/lib/systemd/system/eczos-remote-support-guard.service
grep -Fx 'ExecStart=/usr/lib/eczos-platform-tools/remote-support-guard apply' /usr/lib/systemd/system/eczos-remote-support-guard.service
/usr/lib/eczos-platform-tools/remote-support-guard status --json | jq -e '
    .schemaVersion == 1 and (.installed | type == "boolean") and
    (.serviceActive | type == "boolean") and (.softwareEncoding | type == "boolean")
' >/dev/null
test -x /usr/bin/eczos-ui
test -x /usr/bin/eczos-system-settings
# QStringLiteral stores this value as little-endian UTF-16 in the native
# executable, so inspect that encoding instead of treating the binary as text.
strings -a -el /usr/bin/eczos-system-settings | grep -Fx 'eczos-system-settings.sock' >/dev/null
for label in 'ECZOS appearance' 'Automatic' 'Applying %1 appearance'; do
    strings -a /usr/bin/eczos-system-settings | grep -F "$label" >/dev/null
done
for label in 'Start app' 'Check and repair' 'Fix this app automatically' 'Compatibility engine' 'Advanced mode' \
    'obsolete SafeDisc disc protection' 'Program file' 'Choose another EXE'; do
    if ! strings -a /usr/bin/eczos-system-settings | grep -F "$label" >/dev/null; then
        strings -a -el /usr/bin/eczos-system-settings | grep -F "$label" >/dev/null
    fi
done
dpkg-query -W -f='${Status}\n' eczos-desktop-defaults | grep -Fx 'install ok installed'
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
for desktop in ControlCenter Diagnostics Migration RemoteInputEmergency; do
    desktop-file-validate "/usr/share/applications/org.eczos.${desktop}.desktop"
done
grep -Fx 'Exec=eczos-system-settings' /usr/share/applications/org.eczos.ControlCenter.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:diagnostics' /usr/share/applications/org.eczos.Diagnostics.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:migration' /usr/share/applications/org.eczos.Migration.desktop
grep -Fx 'Exec=eczos-remote-input emergency-stop' /usr/share/applications/org.eczos.RemoteInputEmergency.desktop
test -r /usr/lib/systemd/user/eczos-remote-input.service
test -x /usr/lib/eczos-platform-tools/time-helper
test -r /usr/share/polkit-1/actions/org.eczos.time.policy
grep -Fx 'ExecStart=/usr/bin/eczos-remote-input supervise' /usr/lib/systemd/user/eczos-remote-input.service
grep -Fx 'ExecStopPost=/usr/bin/eczos-remote-input cleanup' /usr/lib/systemd/user/eczos-remote-input.service
grep -F 'os.execv(str(native_host), [str(native_host), "--module", native_page])' /usr/bin/eczos-ui
/usr/bin/eczos-ui --list-kcms-json | jq -e '.schemaVersion == 1 and (.modules | type == "array") and (.modules | length > 10)' >/dev/null
QT_QPA_PLATFORM=offscreen /usr/bin/eczos-system-settings --list-json | jq -e '
    .schemaVersion == 1 and (.eczosPages | length == 12) and
    ([.eczosPages[].id] | contains(["eczos:overview", "eczos:hardware", "eczos:boot", "eczos:windows", "eczos:gaming", "eczos:remote-input", "eczos:network-shares", "eczos:network-optical", "eczos:recovery", "eczos:migration", "eczos:diagnostics", "eczos:support"])) and
    ([.eczosPages[].id] | contains(["eczos:time"]) | not) and
    (.modules | length >= 80) and
    ([.modules[].id] | contains(["kcm_users", "kcm_networkmanagement", "kcm_kscreen", "kcm_printer_manager", "kcm_updates"]))
' >/dev/null
/usr/bin/eczos-time status --json | jq -e '
    .schemaVersion == 1 and (.ntpEnabled | type == "boolean") and
    (.synchronized | type == "boolean") and (.localRtc | type == "boolean") and
    (.hardwareClock == "local" or .hardwareClock == "utc")
' >/dev/null
/usr/bin/eczos-doctor --json | jq -e '
    .schemaVersion == 2 and .office == "installed" and
    (.time.ntpEnabled | type == "boolean") and
    (.memory.totalKiB | type == "number") and
    (.inputSharing.duplicate | type == "boolean") and
    (.remoteSupport.installed | type == "boolean") and
    (.remoteSupport.softwareEncoding | type == "boolean")
' >/dev/null
jq -e '.office.product == "SoftMaker FreeOffice 2024" and .office.package == "softmaker-freeoffice-2024" and .office.redistributed == true' \
    /usr/share/eczos/product/default-apps.json >/dev/null
if /usr/bin/eczos-migrate --dry-run --source / >/dev/null 2>&1; then
    printf 'Migration assistant unexpectedly accepted root-owned execution or / as source.\n' >&2
    exit 1
fi
printf 'eczos-platform-tools installed-package smoke test passed\n'
