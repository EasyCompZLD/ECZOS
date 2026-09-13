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
    packages/eczos-branding/assets/screenshots/settings.png \
    packages/eczos-branding/assets/screenshots/windows-apps.png \
    packages/eczos-branding/assets/screenshots/gaming.png \
    packages/eczos-branding/assets/screenshots/migration.png \
    packages/eczos-branding/assets/screenshots/recovery.png \
    packages/eczos-branding/assets/screenshots/diagnostics.png \
    packages/eczos-branding/assets/screenshots/system-appearance.png \
    packages/eczos-branding/assets/screenshots/system-display.png \
    packages/eczos-branding/assets/screenshots/system-network.png \
    packages/eczos-sddm-theme/debian/control \
    packages/eczos-plymouth-theme/debian/control \
    packages/eczos-plymouth-theme/debian/preinst \
    packages/eczos-plymouth-theme/debian/postrm \
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
    packages/eczos-gaming-core/lib/repair-runtime \
    packages/eczos-gaming-core/polkit/org.eczos.gaming.policy \
    packages/eczos-gaming-core/runtime-definitions/umu-launcher-1.4.0.json \
    packages/eczos-platform-tools/debian/control \
    packages/eczos-platform-tools/bin/eczos-control-center \
    packages/eczos-platform-tools/bin/eczos-ui \
    packages/eczos-platform-tools/native/CMakeLists.txt \
    packages/eczos-platform-tools/native/main.cpp \
    packages/eczos-platform-tools/qml/Main.qml \
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
    image/config/bootloaders/grub-pc/splash.png \
    image/config/bootloaders/grub-pc/live-theme/theme.txt \
    image/config/includes.chroot/etc/skel/.config/ksplashrc \
    image/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session \
    image/config/includes.chroot/etc/calamares/settings.conf \
    image/config/hooks/normal/0110-remove-duplicate-apt-sources.hook.chroot \
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
    scripts/stage-ux-batch-vm.sh \
    scripts/stage-settings-gaming-batch-vm.sh \
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

python3 - "$ROOT_DIR/packages/eczos-platform-tools/bin/eczos-ui" <<'PY' || \
    fail 'invalid ECZOS interface Python source'
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
grep -Fxq '    property bool musicEnabled: true' \
    "$ROOT_DIR/packages/eczos-oobe/qml/Main.qml" || \
    fail 'ECZOS OOBE music is not enabled by default'
grep -Fxq 'Hidden=true' \
    "$ROOT_DIR/packages/eczos-oobe/xdg/org.kde.plasma-welcome.desktop" || \
    fail 'Plasma Welcome autostart is not blocked'
if grep -Fq 'Even geduld' \
    "$ROOT_DIR/packages/eczos-plymouth-theme/theme/eczos.plymouth"; then
    fail 'normal Plymouth boot still contains waiting text'
fi

cmp -s \
    "$ROOT_DIR/image/config/bootloaders/grub-pc/splash.png" \
    "$ROOT_DIR/packages/eczos-branding/assets/wallpapers/eczoswallpaper-dark.png" || \
    fail 'live GRUB does not use the approved ECZOS dark wallpaper'

for frame in $(seq 0 11); do
    for sequence in animation throbber; do
        [[ -s "$ROOT_DIR/packages/eczos-plymouth-theme/theme/images/$sequence-$frame.png" ]] || \
            fail "Plymouth $sequence sequence is missing frame $frame"
    done
done
for support_image in watermark.png bgrt-fallback.png logo.png; do
    printf '%s  %s\n' \
        '8f2b50229408f2d44222ee07e5309938fa82491804cb79a396981ddcb04ac42d' \
        "$ROOT_DIR/packages/eczos-plymouth-theme/theme/images/$support_image" | \
        shasum -a 256 -c - >/dev/null || \
        fail "Plymouth $support_image is not the transparent fallback"
done

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

for screenshot in settings windows-apps gaming migration recovery diagnostics; do
    [[ -s "$ROOT_DIR/packages/eczos-branding/assets/screenshots/$screenshot.png" ]] || \
        fail "missing product screenshot: $screenshot.png"
done
grep -Fq 'branding/screenshots/settings.png' \
    "$ROOT_DIR/packages/eczos-oobe/qml/Main.qml" || \
    fail 'ECZOS OOBE does not use product screenshots'
grep -Fq 'branding/screenshots/windows-apps.png' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/show.qml" || \
    fail 'ECZOS installer does not use product screenshots'

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
