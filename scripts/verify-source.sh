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
    config/debian-extra-components.list \
    docs/architecture.md \
    docs/security.md \
    packages/eczos-branding/debian/control \
    packages/eczos-branding/debian/install \
    packages/eczos-branding/config/zz-eczos-grub.cfg \
    packages/eczos-sddm-theme/debian/control \
    packages/eczos-plymouth-theme/debian/control \
    packages/eczos-plymouth-theme/theme/eczos.plymouth \
    packages/eczos-desktop-defaults/debian/control \
    packages/eczos-desktop-defaults/lib/apply-desktop-defaults \
    packages/eczos-desktop-defaults/config/ksplashrc \
    packages/eczos-release/debian/control \
    packages/eczos-release/apt/eczos-debian.sources \
    packages/eczos-release/lib/update-os-release \
    packages/eczos-release/release/eczos-release \
    packages/eczos-windows-core/debian/control \
    packages/eczos-windows-core/bin/eczos-windows \
    packages/eczos-windows-core/lib/runtime-wine-system \
    packages/eczos-windows-core/applications/org.eczos.Windows.desktop \
    packages/eczos-gaming-core/debian/control \
    packages/eczos-gaming-core/bin/eczos-gaming \
    packages/eczos-gaming-core/lib/runtime-umu \
    packages/eczos-gaming-core/runtime-definitions/umu-launcher-1.4.0.json \
    packages/eczos-platform-tools/debian/control \
    packages/eczos-platform-tools/bin/eczos-control-center \
    packages/eczos-platform-tools/bin/eczos-doctor \
    packages/eczos-platform-tools/bin/eczos-migrate \
    packages/eczos-platform-tools/bin/eczos-support-report \
    packages/eczos-platform-tools/product/default-apps.json \
    packages/eczos-recovery-media/debian/control \
    packages/eczos-recovery-media/bin/eczos-recovery-media \
    packages/eczos-recovery-media/lib/write-media \
    packages/eczos-recovery-media/polkit/org.eczos.recoverymedia.policy \
    packages/eczos-desktop-apps/debian/control \
    packages/eczos-desktop/debian/control \
    packages/eczos-installer/debian/control \
    packages/eczos-installer/bin/eczos-installer \
    packages/eczos-installer/branding/eczos/branding.desc \
    packages/eczos-oobe/debian/control \
    packages/eczos-oobe/bin/eczos-oobe \
    packages/eczos-oobe/qml/Main.qml \
    packages/eczos-oobe/assets/ambient-loop.mp4 \
    packages/eczos-oobe/assets/new-dawn.m4a \
    packages/eczos-desktop-defaults/lookandfeel/org.eczos.desktop/contents/splash/Splash.qml \
    packages/eczos-desktop-defaults/lookandfeel/org.eczos.desktop/contents/splash/eczos-startup.mp4 \
    image/config/bootloaders/grub-pc/grub.cfg \
    image/config/bootloaders/grub-pc/live-theme/theme.txt \
    image/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session \
    image/config/includes.chroot/etc/calamares/settings.conf \
    scripts/configure-freeoffice-repository-vm.sh \
    scripts/test-windows-msi-lifecycle-vm.sh \
    scripts/audit-visible-branding-vm.sh \
    scripts/install-next-product-batch-vm.sh \
    scripts/normalize-image-source-permissions-vm.sh \
    scripts/resume-windows-gates-vm.sh \
    scripts/resume-hardware-qualification-image-vm.sh \
    scripts/build-hardware-qualification-image-vm.sh \
    scripts/build-isolated-hardware-image-vm.sh \
    scripts/stage-prebuild-experience-vm.sh \
    scripts/rebuild-hardware-qualification-from-cache-vm.sh; do
    [[ -f "$ROOT_DIR/$required" ]] || fail "missing $required"
done

while IFS= read -r hook; do
    sh -n "$hook" || fail "invalid image hook syntax: ${hook#"$ROOT_DIR/"}"
done < <(find "$ROOT_DIR/image/config/hooks" -type f -name '*.hook.chroot' -print)

sh -n "$ROOT_DIR/image/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session" || \
    fail 'invalid ECZOS live-session configuration script'

python3 - "$ROOT_DIR/packages/eczos-oobe/bin/eczos-oobe" <<'PY' || \
    fail 'invalid ECZOS OOBE Python source'
import pathlib
import sys
compile(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), sys.argv[1], "exec")
PY

grep -Fxq 'Theme=org.eczos.desktop' \
    "$ROOT_DIR/packages/eczos-desktop-defaults/config/ksplashrc" || \
    fail 'ECZOS splash is not selected system-wide'
grep -Fxq 'welcomeStyleCalamares: false' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/branding.desc" || \
    fail 'Calamares name is still enabled in the welcome heading'
grep -Fq 'visibility: Window.FullScreen' \
    "$ROOT_DIR/packages/eczos-oobe/qml/Main.qml" || \
    fail 'ECZOS OOBE is not configured for full-screen display'

if [[ $(find "$ROOT_DIR/packages/eczos-plymouth-theme/theme/images" -maxdepth 1 \
    -type f -name 'animation-*.png' | wc -l | tr -d ' ') -ne 12 ]]; then
    fail 'Plymouth animation must contain 12 runtime frames'
fi

for asset in \
    assets/login/login-bg.png \
    assets/login/login-logo.png \
    assets/logo/logo.png \
    assets/logo/logo-dark.png \
    assets/wallpapers/eczoswallpaper.png \
    assets/wallpapers/eczoswallpaper-dark.png \
    assets/wallpapers/eczoswallpaper-light.png; do
    [[ -s "$ROOT_DIR/packages/eczos-branding/$asset" ]] || fail "missing or empty branding asset: $asset"
done

while IFS= read -r script; do
    if head -n 1 "$script" | grep -q 'python3'; then
        continue
    fi
    bash -n "$script" || fail "invalid shell syntax: ${script#"$ROOT_DIR/"}"
done < <(find "$ROOT_DIR/scripts" "$ROOT_DIR/tests" "$ROOT_DIR/packages" \
    -type f \( -name '*.sh' -o -path '*/bin/*' -o -path '*/lib/*' \) -print)

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
