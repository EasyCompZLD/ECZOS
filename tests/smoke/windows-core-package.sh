#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-windows-core | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-windows
test -x /usr/lib/eczos/windows/runtime-wine-system
test -r /usr/share/eczos/windows/runtimes/wine-system-v1.json
test -r /usr/share/eczos/windows/schema/application-manifest-v2.json
test -r /usr/share/eczos/windows/dependencies/vcrun2022.json
test -r /usr/share/eczos/windows/dependencies/dotnet48.json
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
grep -F 'detect_installation_media' /usr/bin/eczos-windows
grep -F 'Canonical autorun:' /usr/bin/eczos-windows
grep -F 'autorun.inf' /usr/bin/eczos-windows
grep -F 'zenity --progress' /usr/bin/eczos-windows
grep -F 'rsync -a --partial' /usr/bin/eczos-windows
grep -F '.status="media-copy-failed"' /usr/bin/eczos-windows
grep -F 'product_matches' /usr/bin/eczos-windows
grep -F 'installerWarning=($result != 0)' /usr/bin/eczos-windows
grep -F 'Categories=$category;' /usr/bin/eczos-windows
grep -F 'xdg-user-dir DESKTOP' /usr/bin/eczos-windows
grep -F 'execute-from' /usr/bin/eczos-windows
grep -F 'canonical_working_directory=$(dirname -- "$canonical_entrypoint")' /usr/bin/eczos-windows
grep -F 'Name=ECZ Windows-apps' /usr/share/applications/org.eczos.Windows.Manager.desktop
grep -Fx 'Exec=eczos-system-settings --module eczos:windows' /usr/share/applications/org.eczos.Windows.Manager.desktop
grep -F 'exec wine "$@"' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'canonical_working_directory=$(realpath -e -- "$working_directory")' \
    /usr/lib/eczos/windows/runtime-wine-system
grep -F 'wine32:i386' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'cd "$prefix/drive_c"' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'flock -n "$app_lock_fd"' /usr/bin/eczos-windows
grep -F 'execute-link' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'windows_shortcut="C:\\' /usr/lib/eczos/windows/runtime-wine-system
grep -F "grep -aoP '(?i)[a-z]:" /usr/bin/eczos-windows
grep -F 'rescan_app' /usr/bin/eczos-windows
grep -F '{app_lock_fd}>&-' /usr/bin/eczos-windows
grep -F 'apply_drive_mappings "$manifest" "$prefix"' /usr/bin/eczos-windows
grep -F 'extract_launcher_icon' /usr/bin/eczos-windows
grep -F 'wrestool -x -t 14' /usr/bin/eczos-windows
grep -F 'bwrap --unshare-all' /usr/bin/eczos-windows
grep -F 'map-drive [--yes] APP-ID LETTER DIRECTORY' /usr/bin/eczos-windows
grep -F 'map-optical [--yes] APP-ID LETTER DEVICE MOUNT-DIRECTORY' /usr/bin/eczos-windows
grep -F '"$prefix/dosdevices/$letter::"' /usr/bin/eczos-windows
grep -F 'udisksctl mount --block-device "$device"' /usr/bin/eczos-windows
grep -F 'mounted_directory_for_device' /usr/bin/eczos-windows
grep -F 'apply_known_compatibility_fixes "$prefix"' /usr/bin/eczos-windows
grep -F 'ensure_compatible_session "$manifest"' /usr/bin/eczos-windows
grep -F 'configure_cnc_ddraw_scope "$manifest" "$prefix"' /usr/bin/eczos-windows
grep -F 'automatically repaired $app_id before launch' /usr/bin/eczos-windows
grep -F 'if rescan_app "$app_id"; then' /usr/bin/eczos-windows
grep -F '! -s "$prefix/system.reg"' /usr/bin/eczos-windows
grep -F 'run_with_automatic_recovery' /usr/bin/eczos-windows
grep -F 'last-run.log' /usr/bin/eczos-windows
grep -F 'apply_windows_version' /usr/bin/eczos-windows
grep -F 'rebuild_empty_prefix_architecture' /usr/bin/eczos-windows
grep -F 'export WINEARCH=win32' /usr/bin/eczos-windows
grep -F 'installshield-10-legacy' /usr/bin/eczos-windows
grep -F 'safedisc-driver' /usr/bin/eczos-windows
grep -F 'exec winecfg -v "$1"' /usr/lib/eczos/windows/runtime-wine-system
grep -F 'recovered Wine infrastructure and relaunched $app_id' /usr/bin/eczos-windows
grep -F 'Microsoft Visual C++-onderdeel' /usr/bin/eczos-windows
grep -F '.NET-onderdeel' /usr/bin/eczos-windows
grep -F '.launch.requiredSession = "x11"' /usr/bin/eczos-windows
grep -F 'then .status = "installed-needs-entrypoint"' /usr/bin/eczos-windows
grep -F 'and any(.dependencies[]?; .id == "cnc_ddraw" and .status == "installed")' /usr/bin/eczos-windows
grep -F 'ECZ Windows — andere desktopsessie nodig' /usr/bin/eczos-windows
grep -F 'AppDefaults\\$executable\DllOverrides' /usr/bin/eczos-windows
grep -F 'AppDefaults\worms2.exe\DllOverrides' /usr/bin/eczos-windows
grep -F 'AppDefaults\frontend.exe\DllOverrides' /usr/bin/eczos-windows
grep -F "ECZOS-Install/media/DATA/LEVEL" /usr/bin/eczos-windows
grep -F "0,/^fullscreen=false/{s//fullscreen=true/}" /usr/bin/eczos-windows
grep -F "0,/^maintas=false/{s//maintas=true/}" /usr/bin/eczos-windows
grep -F "0,/^adjmouse=false/{s//adjmouse=true/}" /usr/bin/eczos-windows
grep -F '.drives[$letter]=$directory' /usr/bin/eczos-windows
grep -F "drives 'Stations beheren'" /usr/bin/eczos-windows
grep -F 'migrate_manifest_path' /usr/bin/eczos-windows
grep -F 'schema:2' /usr/bin/eczos-windows
grep -F 'runtime_call_manifest' /usr/bin/eczos-windows
grep -F 'RUNTIME_DEFINITIONS_ROOT' /usr/bin/eczos-windows
grep -F 'winecfg|control|regedit|taskmgr|uninstaller|explorer|cmd' /usr/bin/eczos-windows
grep -F 'install-dependency [--yes] APP-ID DEPENDENCY-ID' /usr/bin/eczos-windows
grep -F 'retry-installer [--check|--yes] APP-ID' /usr/bin/eczos-windows
grep -F "'{ready:true,appId:\$appId,installer:\$installer" /usr/bin/eczos-windows
grep -F '.status="rerunning-installer"' /usr/bin/eczos-windows
grep -F 'install-retry-$(date +%Y%m%d-%H%M%S).log' /usr/bin/eczos-windows
grep -F 'Setup rerun completed and the launcher' /usr/bin/eczos-windows
grep -F 'preferred_media_installer' /usr/bin/eczos-windows
grep -F 'registered_entrypoints' /usr/bin/eczos-windows
grep -F 'discovered_entrypoint_is_valid' /usr/bin/eczos-windows
grep -F 'choose_entrypoint' /usr/bin/eczos-windows
grep -F 'ECZOS_ENTRYPOINT_CHOICE' /usr/bin/eczos-windows
grep -F 'MANAGED_WINETRICKS_VERSION=20260125' /usr/bin/eczos-windows
grep -F 'MANAGED_WINETRICKS_SHA256=431f82fc74000e6c864409f1d8fb495d696c03928808e3e8acffc45179312a7b' /usr/bin/eczos-windows
grep -F 'managed_winetricks' /usr/bin/eczos-windows
grep -F -- "-maxdepth 1 -type d -print0" /usr/bin/eczos-windows
grep -Fq -- '\\DirectPlay\\Applications\\' /usr/bin/eczos-windows
grep -F -- "-iname 'now.ini'" /usr/bin/eczos-windows
grep -F 'installer-failed|installed-needs-entrypoint|rerunning-installer' /usr/bin/eczos-windows
grep -F 'winetricks list-installed' /usr/bin/eczos-windows
grep -F '"$winetricks_bin" -q "$verb"' /usr/bin/eczos-windows
jq -e '.id == "wine-system-v1" and .family == "wine"' \
    /usr/share/eczos/windows/runtimes/wine-system-v1.json >/dev/null
jq -e '.properties.schema.const == 2' \
    /usr/share/eczos/windows/schema/application-manifest-v2.json >/dev/null
jq -e '.properties.launch.properties.requiredSession.enum == ["any", "x11", "wayland"]' \
    /usr/share/eczos/windows/schema/application-manifest-v2.json >/dev/null
for definition in /usr/share/eczos/windows/dependencies/*.json; do
    jq -e '.schema == 1 and .provider == "winetricks" and (.verb | type == "string")' \
        "$definition" >/dev/null
done

migration_root=$(mktemp -d /tmp/eczos-windows-migration.XXXXXX)
trap 'rm -rf "$migration_root"' EXIT
chmod 0711 "$migration_root"
install -d -m 0700 -o nobody -g nogroup "$migration_root/data" "$migration_root/state"
install -d -m 0700 -o nobody -g nogroup \
    "$migration_root/data/eczos/windows/apps/test-app" "$migration_root/state"
install -d -m 0700 -o nobody -g nogroup \
    "$migration_root/data/eczos/windows/apps/test-app/prefix"
jq -n --arg prefix "$migration_root/data/eczos/windows/apps/test-app/prefix" \
    '{schema:1,id:"test-app",name:"Test",runtime:"wine-system-v1",prefix:$prefix,status:"installed",drives:{}}' \
    >"$migration_root/data/eczos/windows/apps/test-app/manifest.json"
chown nobody:nogroup "$migration_root/data/eczos/windows/apps/test-app/manifest.json"
(cd / && /usr/sbin/runuser -u nobody -- env HOME="$migration_root" XDG_DATA_HOME="$migration_root/data" \
    XDG_STATE_HOME="$migration_root/state" /usr/bin/eczos-windows migrate)
jq -e '.schema == 2 and .runner.id == "wine-system-v1" and .windows.architecture == "win64"' \
    "$migration_root/data/eczos/windows/apps/test-app/manifest.json" >/dev/null
test -r "$migration_root/data/eczos/windows/apps/test-app/manifest.schema1.json"

legacy_app="$migration_root/data/eczos/windows/apps/legacy-game"
legacy_prefix="$legacy_app/prefix"
install -d -m 0700 -o nobody -g nogroup \
    "$legacy_prefix/drive_c/Team17/Worms2" \
    "$legacy_prefix/drive_c/Program Files (x86)/Internet Explorer"
printf 'MZ' >"$legacy_prefix/drive_c/Team17/Worms2/worms2.exe"
printf 'MZ' >"$legacy_prefix/drive_c/Team17/Worms2/frontend.exe"
printf 'MZ' >"$legacy_prefix/drive_c/Program Files (x86)/Internet Explorer/iexplore.exe"
printf '%s\n' \
    'WINE REGISTRY Version 2' \
    '' \
    '[Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\iexplore.exe]' \
    '@="C:\\Program Files (x86)\\Internet Explorer\\iexplore.exe"' \
    '' \
    '[Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\Worms2]' \
    '@="C:\\Team17\\Worms2\\Worms2"' \
    '' \
    '[Software\\Wow6432Node\\Microsoft\\DirectPlay\\Applications\\worms2]' \
    '"File"="worms2.exe"' \
    >"$legacy_prefix/system.reg"
jq -n --arg prefix "$legacy_prefix" \
    '{schema:2,id:"legacy-game",name:"Worms2",kind:"exe-installer",runtime:"wine-system-v1",runner:{id:"wine-system-v1",family:"wine",version:null,managedBy:"system"},windows:{version:"win10",architecture:"win64"},dependencies:[],environment:{},dllOverrides:{},graphics:{dxvk:false,vkd3d:false},audio:{driver:"default"},midi:{driver:"default"},launch:{arguments:[]},prefix:$prefix,status:"installed-needs-entrypoint",drives:{},migrations:[]}' \
    >"$legacy_app/manifest.json"
chown -R nobody:nogroup "$legacy_app"
(cd / && /usr/sbin/runuser -u nobody -- env HOME="$migration_root" XDG_DATA_HOME="$migration_root/data" \
    ECZOS_ENTRYPOINT_CHOICE=frontend.exe \
    XDG_STATE_HOME="$migration_root/state" /usr/bin/eczos-windows rescan legacy-game)
jq -e '.status == "installed" and .category == "Game" and (.entrypoint | endswith("/Team17/Worms2/frontend.exe"))' \
    "$legacy_app/manifest.json" >/dev/null
test -r "$migration_root/data/applications/org.eczos.Windows.legacy-game.desktop"

if /usr/bin/eczos-windows list >/dev/null 2>&1; then
    printf 'ECZ Windows unexpectedly allowed a root-owned application session.\n' >&2
    exit 1
fi

printf 'eczos-windows-core installed-package smoke test passed\n'
