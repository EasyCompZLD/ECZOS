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
    config/supported-languages.tsv \
    docs/architecture.md \
    docs/asset-rights-0.1.0.txt \
    docs/asset-provenance.md \
    docs/repository.md \
    docs/security.md \
    repository/conf/distributions.template \
    repository/index.html \
    packages/eczos-archive-keyring/debian/control \
    packages/eczos-archive-keyring/debian/install \
    packages/eczos-archive-keyring/keyrings/eczos-archive-keyring.asc \
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
    packages/eczos-branding/assets/screenshots/browser-firefox.png \
    packages/eczos-branding/assets/screenshots/browser-chrome.png \
    packages/eczos-branding/assets/screenshots/browser-edge.png \
    packages/eczos-branding/assets/screenshots/browser-konqueror.png \
    packages/eczos-branding/assets/screenshots/discover.png \
    packages/eczos-branding/assets/screenshots/plasma-vaults.png \
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
    packages/eczos-release/apt/eczos.sources \
    packages/eczos-release/config/eczos.pref \
    packages/eczos-release/lib/update-os-release \
    packages/eczos-release/config/kcm-about-distrorc \
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
    packages/eczos-gaming-core/po/nl.po \
    packages/eczos-gaming-core/po/de.po \
    packages/eczos-gaming-core/po/fr.po \
    packages/eczos-gaming-core/runtime-definitions/umu-launcher-1.4.0.json \
    packages/eczos-network-optical/debian/control \
    packages/eczos-network-optical/bin/eczos-network-optical \
    packages/eczos-network-optical/lib/helper \
    packages/eczos-network-optical/lib/guard \
    packages/eczos-network-optical/polkit/org.eczos.networkoptical.policy \
    packages/eczos-network-optical/systemd/eczos-network-optical-guard.service \
    packages/eczos-platform-tools/debian/control \
    packages/eczos-platform-tools/bin/eczos-control-center \
    packages/eczos-platform-tools/bin/eczos-ui \
    packages/eczos-platform-tools/bin/systemsettings \
    packages/eczos-platform-tools/bin/kcmshell6 \
    packages/eczos-platform-tools/debian/preinst \
    packages/eczos-platform-tools/debian/postrm \
    packages/eczos-platform-tools/native/CMakeLists.txt \
    packages/eczos-platform-tools/native/main.cpp \
    packages/eczos-platform-tools/po/nl.po \
    packages/eczos-platform-tools/qml/Main.qml \
    packages/eczos-platform-tools/bin/eczos-doctor \
    packages/eczos-platform-tools/bin/eczos-migrate \
    packages/eczos-platform-tools/bin/eczos-support-report \
    packages/eczos-platform-tools/product/default-apps.json \
    packages/eczos-recovery-media/debian/control \
    packages/eczos-recovery-media/bin/eczos-recovery-media \
    packages/eczos-recovery-media/lib/write-media \
    packages/eczos-recovery-media/polkit/org.eczos.recoverymedia.policy \
    packages/eczos-recovery-media/po/nl.po \
    packages/eczos-desktop-apps/debian/control \
    packages/eczos-desktop/debian/control \
    packages/eczos-installer/debian/control \
    packages/eczos-installer/bin/eczos-installer \
    packages/eczos-installer/debian/prerm \
    packages/eczos-installer/branding/eczos/branding.desc \
    packages/eczos-installer/i18n/calamares-eczos_nl.ts \
    packages/eczos-installer/i18n/calamares-eczos_de.ts \
    packages/eczos-installer/i18n/calamares-eczos_fr.ts \
    packages/eczos-oobe/debian/control \
    packages/eczos-oobe/debian/rules \
    packages/eczos-oobe/bin/eczos-oobe \
    packages/eczos-oobe/qml/Main.qml \
    packages/eczos-oobe/i18n/eczos-oobe_nl.ts \
    packages/eczos-oobe/i18n/eczos-oobe_de.ts \
    packages/eczos-oobe/i18n/eczos-oobe_fr.ts \
    packages/eczos-oobe/assets/ambient-loop.mp4 \
    packages/eczos-oobe/assets/new-dawn.m4a \
    packages/eczos-desktop-defaults/lookandfeel/org.eczos.desktop/contents/splash/Splash.qml \
    packages/eczos-desktop-defaults/lookandfeel/org.eczos.desktop/contents/splash/eczos-startup.mp4 \
    packages/eczos-desktop-defaults/lookandfeel/org.eczos.desktop/contents/splash/eczos-startup-poster.png \
    image/config/bootloaders/grub-pc/grub.cfg \
    image/config/bootloaders/grub-pc/splash.png \
    image/config/bootloaders/grub-pc/live-theme/theme.txt \
    image/config/includes.chroot/etc/skel/.config/ksplashrc \
    image/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session \
    image/config/includes.chroot/etc/calamares/settings.conf \
    image/config/hooks/normal/0110-remove-duplicate-apt-sources.hook.chroot \
    image/config/hooks/normal/0120-remove-debian-installer-shortcuts.hook.chroot \
    scripts/configure-freeoffice-repository-vm.sh \
    scripts/init-eczos-repository.sh \
    scripts/import-eczos-repository-packages.sh \
    scripts/publish-eczos-repository.sh \
    scripts/generate-eczos-repository-web.py \
    scripts/verify-release-0.1.0.sh \
    scripts/build-release-packages-vm.sh \
    scripts/publish-release-0.1.0-vm.sh \
    scripts/build-release-image-vm.sh \
    scripts/finalize-release-0.1.0-vm.sh \
    scripts/publish-media-update-0.1.1-vm.sh \
    scripts/unlock-eczos-repository-key.sh \
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
    scripts/stage-network-optical-vm.sh \
    scripts/stage-embedded-settings-hotfix-vm.sh \
    scripts/rebuild-hardware-qualification-from-cache-vm.sh; do
    [[ -f "$ROOT_DIR/$required" ]] || fail "missing $required"
done

LANGUAGE_MATRIX="$ROOT_DIR/config/supported-languages.tsv"
language_count=$(awk -F '\t' '!/^#/ && NF {count++} END {print count + 0}' "$LANGUAGE_MATRIX")
[[ "$language_count" -eq 78 ]] || fail "ECZOS language matrix contains $language_count entries instead of 78"
invalid_language_rows=$(awk -F '\t' '!/^#/ && (NF != 4 || ($4 != "ltr" && $4 != "rtl")) {print NR}' "$LANGUAGE_MATRIX")
[[ -z "$invalid_language_rows" ]] || fail "invalid ECZOS language matrix rows: $invalid_language_rows"
duplicate_language_codes=$(awk -F '\t' '!/^#/ {seen[$1]++} END {for (code in seen) if (seen[code] > 1) print code}' "$LANGUAGE_MATRIX" | sort)
[[ -z "$duplicate_language_codes" ]] || fail "duplicate ECZOS language codes: $duplicate_language_codes"
if grep -Fq 'type="unfinished"' "$ROOT_DIR/packages/eczos-platform-tools/native/i18n/eczos-system-settings_nl.ts"; then
    fail 'Dutch ECZOS Settings catalogue contains unfinished translations'
fi
for catalogue in "$ROOT_DIR"/packages/eczos-oobe/i18n/*.ts; do
    if grep -Fq 'type="unfinished"' "$catalogue"; then
        fail "complete OOBE catalogue contains unfinished translations: ${catalogue#"$ROOT_DIR/"}"
    fi
done
for catalogue in "$ROOT_DIR"/packages/eczos-installer/i18n/*.ts; do
    if grep -Fq 'type="unfinished"' "$catalogue"; then
        fail "complete installer catalogue contains unfinished translations: ${catalogue#"$ROOT_DIR/"}"
    fi
done
if command -v msgfmt >/dev/null 2>&1; then
    for catalogue in \
        "$ROOT_DIR"/packages/eczos-gaming-core/po/*.po \
        "$ROOT_DIR"/packages/eczos-platform-tools/po/nl.po \
        "$ROOT_DIR"/packages/eczos-recovery-media/po/nl.po; do
        msgfmt --check --check-format "$catalogue" -o /dev/null || \
            fail "invalid gettext catalogue: ${catalogue#"$ROOT_DIR/"}"
    done
fi

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

for network_optical_python in \
    "$ROOT_DIR/packages/eczos-network-optical/bin/eczos-network-optical" \
    "$ROOT_DIR/packages/eczos-network-optical/lib/helper" \
    "$ROOT_DIR/packages/eczos-network-optical/lib/guard"; do
    python3 - "$network_optical_python" <<'PY' || \
        fail "invalid network optical drive Python source: ${network_optical_python#"$ROOT_DIR/"}"
import pathlib
import sys
compile(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), sys.argv[1], "exec")
PY
done

grep -Fxq 'Theme=org.eczos.desktop' \
    "$ROOT_DIR/packages/eczos-desktop-defaults/config/ksplashrc" || \
    fail 'ECZOS splash is not selected system-wide'
grep -Fxq 'WatermarkHorizontalAlignment=1.5' \
    "$ROOT_DIR/packages/eczos-plymouth-theme/theme/eczos.plymouth" || \
    fail 'Plymouth watermark is still horizontally visible'
grep -Fxq 'WatermarkVerticalAlignment=1.5' \
    "$ROOT_DIR/packages/eczos-plymouth-theme/theme/eczos.plymouth" || \
    fail 'Plymouth watermark is still vertically visible'
grep -Fxq 'welcomeStyleCalamares: false' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/branding.desc" || \
    fail 'Calamares name is still enabled in the welcome heading'
grep -Fq 'calamares-install-debian.desktop' \
    "$ROOT_DIR/packages/eczos-installer/debian/prerm" || \
    fail 'installer removal does not clean the legacy Debian desktop launcher'
grep -Fq 'calamares-install-debian.desktop' \
    "$ROOT_DIR/packages/eczos-installer/bin/eczos-add-installer-icon" || \
    fail 'live installer setup does not clean the legacy Debian desktop launcher'
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

for screenshot in settings windows-apps gaming migration recovery diagnostics \
    system-appearance system-display system-network application-menu desktop-clean \
    desktop-dark desktop-light game-running about-system steam-library-content \
    browser-firefox browser-chrome browser-edge browser-konqueror discover plasma-vaults; do
    [[ -s "$ROOT_DIR/packages/eczos-branding/assets/screenshots/$screenshot.png" ]] || \
        fail "missing product screenshot: $screenshot.png"
done
grep -Fq 'branding/screenshots/settings.png' \
    "$ROOT_DIR/packages/eczos-oobe/qml/Main.qml" || \
    fail 'ECZOS OOBE does not use product screenshots'
for screenshot in browser-firefox browser-chrome browser-edge browser-konqueror \
    discover plasma-vaults steam-library-content; do
    grep -Fq "branding/screenshots/$screenshot.png" \
        "$ROOT_DIR/packages/eczos-oobe/qml/Main.qml" || \
        fail "ECZOS OOBE does not use $screenshot.png"
done
grep -Fq 'eczos-system-settings", ["--module", "kcm_networkmanagement"]' \
    "$ROOT_DIR/packages/eczos-oobe/bin/eczos-oobe" || \
    fail 'ECZOS OOBE networking does not open in ECZOS Settings'
grep -Fq 'branding/screenshots/windows-apps.png' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/show.qml" || \
    fail 'ECZOS installer does not use product screenshots'
grep -Fq 'branding/screenshots/steam-library-content.png' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/show.qml" || \
    fail 'ECZOS installer does not use the current Steam screenshot'
grep -Fq 'branding/screenshots/oobe-welcome.png' \
    "$ROOT_DIR/packages/eczos-installer/branding/eczos/show.qml" || \
    fail 'ECZOS installer does not preview the current first-run experience'
grep -Fq 'eczos-system-settings.sock' \
    "$ROOT_DIR/packages/eczos-platform-tools/native/main.cpp" || \
    fail 'ECZOS Settings is not single-instance'
grep -Fq 'eczos:network-optical' \
    "$ROOT_DIR/packages/eczos-platform-tools/native/main.cpp" || \
    fail 'ECZOS Settings does not expose network optical drives'
grep -Fq '_eczos-optical._tcp' \
    "$ROOT_DIR/packages/eczos-network-optical/bin/eczos-network-optical" || \
    fail 'network optical discovery does not use the ECZOS DNS-SD service'
grep -Fq 'PSCSIStorageObject' \
    "$ROOT_DIR/packages/eczos-network-optical/lib/helper" || \
    fail 'network optical sharing does not use an LIO pSCSI backstore'
grep -Fq 'generate_node_acls' \
    "$ROOT_DIR/packages/eczos-network-optical/lib/guard" || \
    fail 'network optical sharing lacks the exclusive-access ACL guard'
grep -Fq 'LookAndFeelPackage' \
    "$ROOT_DIR/packages/eczos-desktop-defaults/bin/eczos-theme-switch" || \
    fail 'ECZOS appearance selection does not persist its global theme'

while IFS= read -r script; do
    # Debian package builds leave native ELF binaries below debian/*/usr/bin
    # and debug artefacts below debian/.debhelper.  They can legitimately
    # match the source path patterns below, but must never be parsed as shell.
    if [[ "$script" != *.sh ]]; then
        grep -Iq . "$script" || continue
        first_line=$(head -n 1 "$script" || true)
        case "$first_line" in
            '#!'*python*) continue ;;
            '#!'*sh*|'#!'*bash*) ;;
            *) continue ;;
        esac
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
