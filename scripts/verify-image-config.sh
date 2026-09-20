#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"

for required in \
    auto/config \
    auto/clean \
    auto/build \
    config/package-lists/eczos-desktop.list.chroot \
    config/hooks/normal/0090-eczos-product-policy.hook.chroot \
    config/hooks/normal/0100-eczos-image-policy.hook.chroot \
    config/hooks/normal/0110-remove-duplicate-apt-sources.hook.chroot \
    config/hooks/normal/0120-remove-debian-installer-shortcuts.hook.chroot \
    config/bootloaders/grub-pc/grub.cfg \
    config/bootloaders/grub-pc/splash.png \
    config/bootloaders/grub-pc/live-theme/theme.txt \
    config/includes.chroot/etc/skel/.config/ksplashrc \
    config/includes.chroot/etc/calamares/settings.conf \
    config/includes.chroot/etc/calamares/modules/users.conf \
    config/includes.chroot/etc/calamares/modules/packages.conf \
    config/includes.chroot/etc/calamares/modules/bootloader.conf \
    config/includes.chroot/etc/default/grub.d/90-eczos-plymouth.cfg \
    config/includes.chroot/usr/lib/live/config/1095-eczos-live-session \
    config/includes.chroot/usr/share/applications/calamares-install-debian.desktop \
    config/includes.chroot/etc/apt/sources.list.d/softmaker.list \
    config/includes.chroot/usr/share/keyrings/softmaker-archive-keyring.asc; do
    test -s "$IMAGE_DIR/$required"
done

grep -Fx 'live-task-kde' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -Fx 'calamares' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -Fx 'calamares-settings-debian' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
if grep -Fx 'debian-installer-launcher' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"; then
    printf 'Debian Installer launcher must not be present in the ECZOS image.\n' >&2
    exit 1
fi
grep -Fx 'linux-image-amd64' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -Fx 'mesa-vulkan-drivers:i386' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -F 'apt-get purge -y' "$IMAGE_DIR/config/hooks/normal/0090-eczos-product-policy.hook.chroot"
grep -F 'flatpak remote-add --system' "$IMAGE_DIR/config/hooks/normal/0090-eczos-product-policy.hook.chroot"
grep -F -- '--distribution trixie' "$IMAGE_DIR/auto/config"
grep -F -- '--archive-areas "main contrib non-free non-free-firmware"' "$IMAGE_DIR/auto/config"
grep -F -- '--debian-installer none' "$IMAGE_DIR/auto/config"
grep -F -- 'quiet splash' "$IMAGE_DIR/auto/config"
grep -F -- 'username=eczos user-fullname=ECZOS hostname=eczos-live' \
    "$IMAGE_DIR/auto/config"
grep -Fx 'Autolock=false' \
    "$IMAGE_DIR/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session"
grep -Fq 'calamares-install-debian.desktop' \
    "$IMAGE_DIR/config/includes.chroot/usr/lib/live/config/1095-eczos-live-session"
grep -Fq 'calamares-install-debian.desktop' \
    "$IMAGE_DIR/config/hooks/normal/0120-remove-debian-installer-shortcuts.hook.chroot"
grep -F 'menuentry "ECZOS proberen"' \
    "$IMAGE_DIR/config/bootloaders/grub-pc/grub.cfg"
grep -F 'menuentry "ECZOS installeren"' \
    "$IMAGE_DIR/config/bootloaders/grub-pc/grub.cfg"
grep -Fx 'desktop-image: "../splash.png"' \
    "$IMAGE_DIR/config/bootloaders/grub-pc/live-theme/theme.txt"
cmp -s \
    "$IMAGE_DIR/config/bootloaders/grub-pc/splash.png" \
    "$ROOT_DIR/packages/eczos-branding/assets/wallpapers/eczoswallpaper-dark.png"
grep -Fx 'Theme=org.eczos.desktop' \
    "$IMAGE_DIR/config/includes.chroot/etc/skel/.config/ksplashrc"
grep -Fx 'branding: eczos' \
    "$IMAGE_DIR/config/includes.chroot/etc/calamares/settings.conf"
grep -Fx '  - sudo' \
    "$IMAGE_DIR/config/includes.chroot/etc/calamares/modules/users.conf"
grep -Fx 'efiBootloaderId: ECZOS' \
    "$IMAGE_DIR/config/includes.chroot/etc/calamares/modules/bootloader.conf"
grep -Fx '      - eczos-installer' \
    "$IMAGE_DIR/config/includes.chroot/etc/calamares/modules/packages.conf"
grep -Fx 'plymouth-set-default-theme eczos' \
    "$IMAGE_DIR/config/hooks/normal/0100-eczos-image-policy.hook.chroot"
grep -Fx 'rm -f /etc/apt/sources.list' \
    "$IMAGE_DIR/config/hooks/normal/0110-remove-duplicate-apt-sources.hook.chroot"
grep -Fx 'rm -f /etc/apt/sources.list.d/zz-sources.list' \
    "$IMAGE_DIR/config/hooks/normal/0110-remove-duplicate-apt-sources.hook.chroot"
grep -F 'softmaker-archive-keyring.asc' \
    "$IMAGE_DIR/config/includes.chroot/etc/apt/sources.list.d/softmaker.list"
grep -F 'BEGIN PGP PUBLIC KEY BLOCK' \
    "$IMAGE_DIR/config/includes.chroot/usr/share/keyrings/softmaker-archive-keyring.asc"
printf '%s  %s\n' \
    '2c03e53ad4b1cb442f12c9af5052fb490547922b8b64e02f334f30a9f2de7f74' \
    "$IMAGE_DIR/config/includes.chroot/usr/share/keyrings/softmaker-archive-keyring.asc" | sha256sum -c - >/dev/null

if grep -REn --exclude=README.md --exclude='8*.hook.chroot' \
    '/build/easycomp-desktop|machine-id|ECZHOATOOL|onlyoffice-desktopeditors' \
    "$IMAGE_DIR/auto" "$IMAGE_DIR/config"; then
    printf 'Historical or machine-specific content found in image source.\n' >&2
    exit 1
fi

printf 'ECZOS image configuration verification passed\n'
