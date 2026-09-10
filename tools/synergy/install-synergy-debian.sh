#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Start dit script als root (bijvoorbeeld: su -).\n' >&2
    exit 2
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEB_ARCH=$(dpkg --print-architecture)
if [[ "$DEB_ARCH" != amd64 ]]; then
    printf 'Deze USB-bundel bevat alleen de Synergy amd64-build. Gevonden: %s\n' "$DEB_ARCH" >&2
    exit 1
fi

SYNERGY_DEB=$(find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'synergy_*_debian_amd64.deb' -print -quit)
LIBSSL_DEB=$(find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'libssl1.1_*_amd64.deb' -print -quit)
[[ -n "$SYNERGY_DEB" && -f "$SYNERGY_DEB" ]] || {
    printf 'Synergy Debian amd64-pakket ontbreekt naast dit script.\n' >&2
    exit 1
}
[[ -n "$LIBSSL_DEB" && -f "$LIBSSL_DEB" ]] || {
    printf 'Compatibiliteitspakket libssl1.1 ontbreekt naast dit script.\n' >&2
    exit 1
}

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y "$LIBSSL_DEB" "$SYNERGY_DEB"

if command -v synergy >/dev/null 2>&1; then
    synergy --version || true
fi
if command -v synergyc >/dev/null 2>&1; then
    missing=$(ldd "$(command -v synergyc)" | awk '/not found/ {print $1}')
    [[ -z "$missing" ]] || {
        printf 'Synergy heeft ontbrekende bibliotheken: %s\n' "$missing" >&2
        exit 1
    }
fi

printf 'Synergy 1.10.1 is geïnstalleerd met Debian-compatibiliteit.\n'
printf 'Start het via het programmamenu of met: synergy\n'
