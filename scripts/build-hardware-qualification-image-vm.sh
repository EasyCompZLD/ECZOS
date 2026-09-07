#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 build host.\n' >&2
    exit 2
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi
if [[ ${ECZOS_HARDWARE_QUALIFICATION:-} != 1 ]]; then
    printf 'Set ECZOS_HARDWARE_QUALIFICATION=1 to build the non-release hardware test ISO.\n' >&2
    exit 2
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"
BUILD_DIR="$IMAGE_DIR/.build"
ARTIFACT_DIR="$BUILD_DIR/artifacts"
LOG_DIR="$BUILD_DIR/logs"
BUILD_ID=$(date -u +%Y%m%d-%H%M%S)
ISO_NAME="ECZOS-hardware-qualification-amd64-${BUILD_ID}.iso"

for command_name in lb dpkg-buildpackage dpkg-parsechangelog lintian sha256sum xorriso; do
    command -v "$command_name" >/dev/null || {
        printf 'Missing build dependency: %s\n' "$command_name" >&2
        exit 1
    }
done

mkdir -p "$ARTIFACT_DIR" "$LOG_DIR"
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"

cd "$IMAGE_DIR"
./auto/clean
ECZOS_ISO_VOLUME=ECZOS_HWQUAL_AMD64 \
ECZOS_ISO_APPLICATION='ECZOS Hardware Qualification' ./auto/config
"$ROOT_DIR/scripts/prepare-image-packages-vm.sh"

export MKSQUASHFS_OPTIONS="-processors $(nproc)"
if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_DATE_EPOCH=$(git -C "$ROOT_DIR" log -1 --format=%ct)
else
    SOURCE_DATE_EPOCH=$(date -u +%s)
fi
export SOURCE_DATE_EPOCH

./auto/build 2>&1 | tee "$LOG_DIR/hardware-qualification-${BUILD_ID}.log"

BUILT_ISO="$IMAGE_DIR/live-image-amd64.hybrid.iso"
if [[ ! -f "$BUILT_ISO" ]]; then
    printf 'live-build finished without the expected ISO.\n' >&2
    exit 1
fi

install -m 0644 "$BUILT_ISO" "$ARTIFACT_DIR/$ISO_NAME"
(cd "$ARTIFACT_DIR" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256")
printf '\nHardware-qualification ISO completed (not a public release):\n%s\n' \
    "$ARTIFACT_DIR/$ISO_NAME"
cat "$ARTIFACT_DIR/$ISO_NAME.sha256"
