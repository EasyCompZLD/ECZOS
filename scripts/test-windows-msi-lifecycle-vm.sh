#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

TEST_USER=${ECZOS_TEST_USER:-}
if [[ -z "$TEST_USER" ]]; then
    mapfile -t users < <(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\// {print $1}')
    if [[ ${#users[@]} -ne 1 ]]; then
        printf 'Set ECZOS_TEST_USER to the desktop account; automatic detection found %d candidates.\n' \
            "${#users[@]}" >&2
        exit 2
    fi
    TEST_USER=${users[0]}
fi
TEST_HOME=$(getent passwd "$TEST_USER" | awk -F: '{print $6}')
[[ -n "$TEST_HOME" && "$TEST_HOME" != /root && -d "$TEST_HOME" ]] || {
    printf 'Invalid ECZOS test user: %s\n' "$TEST_USER" >&2
    exit 2
}

apt-get install -y bubblewrap icoutils msitools wine xvfb xauth
PE_SOURCE=$(find /usr/lib -type f -iname notepad.exe -print -quit 2>/dev/null || true)
[[ -n "$PE_SOURCE" ]] || {
    printf 'Could not find Wine notepad.exe for the harmless MSI fixture.\n' >&2
    exit 1
}

TEMP_DIR=$(mktemp -d /tmp/eczos-msi-lifecycle.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT
MSI_FILE="$TEMP_DIR/eczos-msi-test.msi"
cat >"$TEMP_DIR/eczos-msi-test.wxs" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="ECZOS MSI Test" Language="1033" Version="1.0.0"
           Manufacturer="EasyComp Zeeland" UpgradeCode="{3D1882A6-CA19-46CC-B2E5-C81A43F8C5A8}">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perUser" />
    <Media Id="1" Cabinet="eczos.cab" EmbedCab="yes" />
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLDIR" Name="ECZOS MSI Test">
          <Component Id="MainExecutable" Guid="{F474F6E3-2B36-4DB1-A826-A1432F90C28F}">
            <File Id="MainExe" Name="ECZOSMsiTest.exe" Source="$PE_SOURCE" KeyPath="yes" />
          </Component>
        </Directory>
      </Directory>
    </Directory>
    <Feature Id="Complete" Title="ECZOS MSI Test" Level="1">
      <ComponentRef Id="MainExecutable" />
    </Feature>
  </Product>
</Wix>
EOF
wixl -o "$MSI_FILE" "$TEMP_DIR/eczos-msi-test.wxs"
chmod 0644 "$MSI_FILE"

run_as_user() {
    runuser -u "$TEST_USER" -- env \
        HOME="$TEST_HOME" USER="$TEST_USER" LOGNAME="$TEST_USER" \
        PATH=/usr/local/bin:/usr/bin:/bin "$@"
}

install_output=$(run_as_user xvfb-run -a eczos-windows install --yes "$MSI_FILE")
printf '%s\n' "$install_output"
app_id=$(sed -n 's/^ECZ Windows application ID: //p' <<<"$install_output" | tail -n1)
[[ -n "$app_id" ]] || { printf 'The MSI test did not return an application ID.\n' >&2; exit 1; }
manifest="$TEST_HOME/.local/share/eczos/windows/apps/$app_id/manifest.json"
run_as_user jq -e \
    '.kind == "msi-installer" and .status == "installed" and (.entrypoint | endswith("/ECZOSMsiTest.exe")) and (.icon | endswith("/application.png"))' \
    "$manifest" >/dev/null
icon=$(run_as_user jq -r '.icon' "$manifest")
test -s "$icon"
prefix=$(run_as_user jq -r '.prefix' "$manifest")
test ! -e "$prefix/dosdevices/z:"
run_as_user xvfb-run -a eczos-windows repair "$app_id"
run_as_user eczos-windows remove --yes "$app_id"
test ! -e "$manifest"

printf 'ECZ Windows MSI, icon extraction, repair and recoverable removal test passed for %s.\n' "$TEST_USER"
