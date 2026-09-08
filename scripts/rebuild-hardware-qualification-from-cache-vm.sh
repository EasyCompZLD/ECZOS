#!/usr/bin/env bash
set -Eeuo pipefail
# Compatibility entry point. Never force stages in an interrupted build tree.
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
exec bash "$ROOT_DIR/scripts/build-isolated-hardware-image-vm.sh" "$@"
