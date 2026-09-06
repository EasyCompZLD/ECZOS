#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie || $(dpkg --print-architecture) != amd64 ]]; then
    printf 'Refusing to run: Debian 13 amd64 is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEFINITION="$ROOT_DIR/packages/eczos-gaming-core/runtime-definitions/umu-launcher-1.4.0.json"
URL=$(jq -er .url "$DEFINITION")
EXPECTED_SHA256=$(jq -er .sha256 "$DEFINITION")
EXPECTED_PACKAGE=$(jq -er .package "$DEFINITION")
EXPECTED_VERSION=$(jq -er .version "$DEFINITION")
TEMP_DIR=$(mktemp -d /tmp/eczos-gaming-runtime.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT
DEB="$TEMP_DIR/umu-launcher.deb"

dpkg --add-architecture i386
apt-get update
apt-get install -y curl gamemode jq mesa-vulkan-drivers mesa-vulkan-drivers:i386 vulkan-tools
curl --fail --location --proto '=https' --tlsv1.2 --output "$DEB" "$URL"
printf '%s  %s\n' "$EXPECTED_SHA256" "$DEB" | sha256sum --check --strict

[[ $(dpkg-deb --field "$DEB" Package) == "$EXPECTED_PACKAGE" ]]
[[ $(dpkg-deb --field "$DEB" Version) == "$EXPECTED_VERSION" ]]
[[ $(dpkg-deb --field "$DEB" Architecture) == amd64 ]]
apt-get install -y "$DEB"

printf '\nGaming runtime prerequisites installed. Run: eczos-gaming doctor\n'
