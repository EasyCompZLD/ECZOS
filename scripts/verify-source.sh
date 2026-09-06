#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ERRORS=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    ERRORS=$((ERRORS + 1))
}

for required in \
    README.md \
    docs/architecture.md \
    docs/security.md \
    packages/eczos-branding/debian/control \
    packages/eczos-branding/debian/install \
    packages/eczos-sddm-theme/debian/control \
    packages/eczos-plymouth-theme/debian/control \
    packages/eczos-plymouth-theme/theme/eczos.plymouth \
    packages/eczos-desktop-defaults/debian/control \
    packages/eczos-desktop-defaults/lib/apply-desktop-defaults \
    packages/eczos-release/debian/control \
    packages/eczos-release/release/eczos-release \
    packages/eczos-desktop/debian/control; do
    [[ -f "$ROOT_DIR/$required" ]] || fail "missing $required"
done

if [[ $(find "$ROOT_DIR/packages/eczos-plymouth-theme/theme/images" -maxdepth 1 \
    -type f -name 'animation-*.png' | wc -l | tr -d ' ') -ne 12 ]]; then
    fail 'Plymouth animation must contain 12 runtime frames'
fi

for asset in \
    assets/login/login-bg.png \
    assets/login/login-logo.png \
    assets/logo/logo.png \
    assets/wallpapers/eczoswallpaper.png \
    assets/wallpapers/eczoswallpaper-dark.png \
    assets/wallpapers/eczoswallpaper-light.png; do
    [[ -s "$ROOT_DIR/packages/eczos-branding/$asset" ]] || fail "missing or empty branding asset: $asset"
done

while IFS= read -r script; do
    bash -n "$script" || fail "invalid shell syntax: ${script#"$ROOT_DIR/"}"
done < <(find "$ROOT_DIR/scripts" "$ROOT_DIR/tests" -type f -name '*.sh' -print)

"$ROOT_DIR/scripts/verify-image-config.sh" || fail 'invalid image configuration'

if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$ROOT_DIR" ls-files | grep -E '\.(iso|deb)$' >/dev/null; then
        fail 'ISO or binary Debian package is tracked by Git'
    fi
    if git -C "$ROOT_DIR" ls-files | grep -E '(^|/)(machine-id|fstab)$' >/dev/null; then
        fail 'machine-specific identity or filesystem configuration is tracked'
    fi
fi

if [[ "$ERRORS" -ne 0 ]]; then
    printf '%d source verification failure(s)\n' "$ERRORS" >&2
    exit 1
fi

printf 'ECZOS source verification passed\n'
