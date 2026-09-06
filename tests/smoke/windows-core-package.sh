#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-windows-core | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-windows
test -x /usr/lib/eczos/windows/runtime-wine-system
test -r /usr/share/applications/org.eczos.Windows.desktop
test -r /usr/share/applications/org.eczos.Windows.Manager.desktop
test -r /etc/xdg/autostart/eczos-windows-first-run.desktop
bash -n /usr/bin/eczos-windows
bash -n /usr/lib/eczos/windows/runtime-wine-system
/usr/lib/eczos/windows/runtime-wine-system check | grep -E '^wine-[0-9]'
grep -F 'MimeType=application/x-ms-dos-executable;application/vnd.microsoft.portable-executable;application/x-msi;' \
    /usr/share/applications/org.eczos.Windows.desktop
grep -F 'restrict_prefix "$prefix"' /usr/bin/eczos-windows
grep -F 'rm -f "$prefix/dosdevices/z:"' /usr/bin/eczos-windows
grep -F 'gio trash "$app_dir"' /usr/bin/eczos-windows
grep -F 'C:\\ECZOS-Install\\payload.$extension' /usr/bin/eczos-windows
grep -F 'Name=ECZ Windows-apps' /usr/share/applications/org.eczos.Windows.Manager.desktop
grep -F 'exec wine "$@"' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'wine32:i386' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'cd "$prefix/drive_c"' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'flock -n "$app_lock_fd"' /usr/bin/eczos-windows
grep -F 'execute-link' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'windows_shortcut="C:\\' /usr/lib/eczos/windows/runtime-wine-system
grep -F "grep -aoP '(?i)[a-z]:" /usr/bin/eczos-windows
grep -F 'rescan_app' /usr/bin/eczos-windows
grep -F '{app_lock_fd}>&-' /usr/bin/eczos-windows
grep -F 'apply_drive_mappings "$manifest" "$prefix"' /usr/bin/eczos-windows
grep -F 'map-drive [--yes] APP-ID LETTER DIRECTORY' /usr/bin/eczos-windows
grep -F '.drives[$letter]=$directory' /usr/bin/eczos-windows
grep -F "drives 'Stations beheren'" /usr/bin/eczos-windows

if /usr/bin/eczos-windows list >/dev/null 2>&1; then
    printf 'ECZ Windows unexpectedly allowed a root-owned application session.\n' >&2
    exit 1
fi

printf 'eczos-windows-core installed-package smoke test passed\n'
