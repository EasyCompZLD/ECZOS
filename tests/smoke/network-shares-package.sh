#!/usr/bin/env bash
set -Eeuo pipefail
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-network-shares | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-network-shares
python3 -m py_compile /usr/bin/eczos-network-shares
work=$(mktemp -d /tmp/eczos-network-shares-test.XXXXXX)
trap 'rm -rf "$work"' EXIT
chown nobody:nogroup "$work"
run=(runuser -u nobody -- env HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_DATA_HOME="$work/data" /usr/bin/eczos-network-shares)
entry=$("${run[@]}" add --name 'Test share' --url 'smb://files.example.test/shared folder')
identifier=$(jq -er .id <<<"$entry")
"${run[@]}" list --json | jq -e --arg id "$identifier" '.schemaVersion == 1 and (.shares | length == 1) and .shares[0].id == $id and .shares[0].protocol == "SMB" and (.existing | type == "array") and (.mounted | type == "array")' >/dev/null
test -f "$work/data/remoteview/eczos-$identifier.desktop"
grep -Fx 'X-ECZOS-Managed=true' "$work/data/remoteview/eczos-$identifier.desktop"
if "${run[@]}" add --name Unsafe --url 'smb://user:secret@files.example.test/share' >/dev/null 2>&1; then
    printf 'A password embedded in a network URL was accepted.\n' >&2
    exit 1
fi
"${run[@]}" remove "$identifier" >/dev/null
"${run[@]}" list --json | jq -e '.shares == []' >/dev/null
printf 'eczos-network-shares installed-package smoke test passed\n'
