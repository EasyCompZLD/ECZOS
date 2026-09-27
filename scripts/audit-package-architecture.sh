#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
failure=0
desktop="$ROOT_DIR/packages/eczos-desktop/debian/control"
apps="$ROOT_DIR/packages/eczos-desktop-apps/debian/control"
depends=$(sed -n '/^Depends:/,/^[A-Z][A-Za-z-]*:/p' "$desktop")
recommends=$(sed -n '/^Recommends:/,/^[A-Z][A-Za-z-]*:/p' "$desktop")
for package in eczos-boot-tools eczos-desktop-apps eczos-gaming-core eczos-hardware-tools eczos-network-shares eczos-network-optical eczos-recovery-media eczos-windows-core; do
    if grep -Eq "^[[:space:]]*$package([[:space:](,]|$)" <<<"$depends"; then printf 'Optional module is a hard dependency: %s\n' "$package" >&2; failure=1; fi
    grep -Eq "^[[:space:]]*$package([[:space:](,]|$)" <<<"$recommends" || { printf 'Optional module is not recommended: %s\n' "$package" >&2; failure=1; }
done
hard_apps=$(sed -n '/^Depends:/,/^[A-Z][A-Za-z-]*:/p' "$apps" | grep -Ev '^(Depends:|Recommends:|[[:space:]]*\$\{misc:Depends\},?[[:space:]]*$|[[:space:]]*$)' || true)
[[ -z "$hard_apps" ]] || { printf 'eczos-desktop-apps contains hard application dependencies:\n%s\n' "$hard_apps" >&2; failure=1; }
((failure == 0)) || exit 1
printf 'ECZOS package architecture audit passed: feature and application sets remain removable.\n'
