#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie || $(dpkg --print-architecture) != amd64 ]]; then
    printf 'Refusing to run: Debian 13 (trixie) amd64 is required.\n' >&2
    exit 1
fi

KEY_URL=https://shop.softmaker.com/repo/apt/softmaker-repo.asc
KEY_SHA256=2c03e53ad4b1cb442f12c9af5052fb490547922b8b64e02f334f30a9f2de7f74
KEYRING=/usr/share/keyrings/softmaker-archive-keyring.gpg
SOURCE_LIST=/etc/apt/sources.list.d/softmaker.list
PREFERENCES=/etc/apt/preferences.d/eczos-softmaker
PACKAGE=softmaker-freeoffice-2024
TEMP_DIR=$(mktemp -d /tmp/eczos-freeoffice-repository.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

apt-get update
apt-get install -y ca-certificates curl gnupg
curl --fail --show-error --location --proto '=https' --tlsv1.2 \
    --retry 3 --output "$TEMP_DIR/softmaker-repo.asc" "$KEY_URL"
printf '%s  %s\n' "$KEY_SHA256" "$TEMP_DIR/softmaker-repo.asc" | sha256sum --check --status
gpg --batch --dearmor --output "$TEMP_DIR/softmaker.gpg" "$TEMP_DIR/softmaker-repo.asc"
install -m 0644 "$TEMP_DIR/softmaker.gpg" "$KEYRING"
printf '%s\n' \
    "deb [arch=amd64 signed-by=$KEYRING] https://shop.softmaker.com/repo/apt stable non-free" \
    >"$SOURCE_LIST"
cat >"$PREFERENCES" <<'EOF'
Package: *
Pin: origin "shop.softmaker.com"
Pin-Priority: 1

Package: softmaker-freeoffice-2024
Pin: origin "shop.softmaker.com"
Pin-Priority: 500
EOF

apt-get update
candidate=$(apt-cache policy "$PACKAGE" | awk '/Candidate:/ {print $2; exit}')
if [[ -z "$candidate" || "$candidate" = '(none)' ]]; then
    printf 'The signed SoftMaker repository does not offer %s.\n' "$PACKAGE" >&2
    exit 1
fi
apt-get install -y "$PACKAGE"
dpkg-query -W -f='${Status}\n' "$PACKAGE" | grep -Fx 'install ok installed'

installed_version=$(dpkg-query -W -f='${Version}' "$PACKAGE")
printf 'FreeOffice installed from the signed vendor repository: %s\n' "$installed_version"
