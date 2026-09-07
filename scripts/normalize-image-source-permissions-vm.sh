#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"

# SMB shares can expose every source file as owner-only executable. Normalize
# live-build inputs so copied runtime data remains readable inside the image.
find "$IMAGE_DIR/config/includes.chroot" -type d -exec chmod 0755 {} +
find "$IMAGE_DIR/config/includes.chroot" -type f -exec chmod 0644 {} +
find "$IMAGE_DIR/config/package-lists" -type d -exec chmod 0755 {} +
find "$IMAGE_DIR/config/package-lists" -type f -exec chmod 0644 {} +
find "$IMAGE_DIR/config/hooks" -type d -exec chmod 0755 {} +
find "$IMAGE_DIR/config/hooks" -type f -name '*.hook.chroot' -exec chmod 0755 {} +
chmod 0755 "$IMAGE_DIR/auto/build" "$IMAGE_DIR/auto/clean" "$IMAGE_DIR/auto/config"

printf 'ECZOS live-build source permissions normalized\n'
