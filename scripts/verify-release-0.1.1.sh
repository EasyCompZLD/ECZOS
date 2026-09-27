#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ERRORS=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    ERRORS=$((ERRORS + 1))
}

checked=0
for changelog in "$ROOT_DIR"/packages/eczos-*/debian/changelog; do
    package_dir=${changelog%/debian/changelog}
    package=$(basename "$package_dir")
    first_line=$(head -n 1 "$changelog")
    version=$(printf '%s\n' "$first_line" | sed -E 's/^[^(]+\(([^)]+)\).*/\1/')
    distribution=$(printf '%s\n' "$first_line" | sed -E 's/^.*\)[[:space:]]+([^;]+);.*/\1/')
    case "$package" in
        eczos-archive-keyring) expected=2026.09.27 ;;
        eczos-boot-tools|eczos-hardware-tools|eczos-network-shares|eczos-platform-core) expected=0.1.0 ;;
        eczos-platform-tools|eczos-recovery-media) expected=0.1.2 ;;
        eczos-branding|eczos-desktop|eczos-desktop-apps|eczos-desktop-defaults|eczos-gaming-core|eczos-installer|eczos-network-optical|eczos-oobe|eczos-plymouth-theme|eczos-release|eczos-sddm-theme|eczos-windows-core) expected=0.1.1 ;;
        *) expected= ;;
    esac
    [[ -n "$expected" ]] || { fail "unexpected ECZOS package: $package"; continue; }
    [[ "$version" == "$expected" ]] || fail "$package is $version, expected $expected"
    [[ "$distribution" == trixie ]] || fail "$package targets $distribution, expected trixie"
    checked=$((checked + 1))
done
[[ $checked -eq 19 ]] || fail "checked $checked packages, expected 19"

if grep -REn 'Depends:|^[[:space:]]+eczos-' "$ROOT_DIR"/packages/eczos-*/debian/control | \
   grep -E '~dev[0-9]+'; then
    fail 'a release package still depends on an ECZOS development version'
fi

grep -Fxq 'ECZOS_PRETTY_NAME="ECZOS 0.1.1"' \
    "$ROOT_DIR/packages/eczos-release/release/eczos-release" || \
    fail 'release identity is not ECZOS 0.1.1'
grep -Fxq 'ECZOS_CHANNEL=stable' \
    "$ROOT_DIR/packages/eczos-release/release/eczos-release" || \
    fail 'release channel is not stable'
grep -Fq 'PRETTY_NAME="ECZOS 0.1.1"' \
    "$ROOT_DIR/packages/eczos-release/lib/update-os-release" || \
    fail '/etc/os-release generator is not ECZOS 0.1.1'
[[ $(awk '/^Status:/ {print; exit}' "$ROOT_DIR/docs/asset-rights-0.1.1.txt") == \
   'Status: approved-for-eczos-0.1.1' ]] || \
    fail 'asset rights have not been explicitly recorded for ECZOS 0.1.1'
[[ ! -e "$ROOT_DIR/image/BUILD_BLOCKED.md" ]] || \
    fail 'image/BUILD_BLOCKED.md still blocks the release'
if grep -REn \
   'may not be redistributed|awaiting-owner-confirmation|formal project license has been approved' \
   "$ROOT_DIR/packages"/eczos-*/debian/copyright "$ROOT_DIR/docs/asset-rights-0.1.1.txt"; then
    fail 'release copyright metadata still contains a distribution blocker'
fi

if [[ "$ERRORS" -ne 0 ]]; then
    printf '%d release verification failure(s)\n' "$ERRORS" >&2
    exit 1
fi

printf 'ECZOS 0.1.1 release metadata verification passed\n'
