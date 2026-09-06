#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"

for required in \
    auto/config \
    auto/clean \
    auto/build \
    config/package-lists/eczos-desktop.list.chroot \
    config/hooks/normal/0100-eczos-image-policy.hook.chroot \
    config/includes.chroot/etc/default/grub.d/90-eczos-plymouth.cfg; do
    test -s "$IMAGE_DIR/$required"
done

grep -Fx 'live-task-kde' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -Fx 'debian-installer-launcher' "$IMAGE_DIR/config/package-lists/eczos-desktop.list.chroot"
grep -F -- '--distribution trixie' "$IMAGE_DIR/auto/config"
grep -F -- '--debian-installer live' "$IMAGE_DIR/auto/config"
grep -F -- 'quiet splash' "$IMAGE_DIR/auto/config"
grep -Fx 'plymouth-set-default-theme eczos' \
    "$IMAGE_DIR/config/hooks/normal/0100-eczos-image-policy.hook.chroot"

if grep -REn --exclude=README.md \
    '/build/easycomp-desktop|machine-id|ECZHOATOOL|onlyoffice' "$IMAGE_DIR"; then
    printf 'Historical or machine-specific content found in image source.\n' >&2
    exit 1
fi

printf 'ECZOS image configuration verification passed\n'
