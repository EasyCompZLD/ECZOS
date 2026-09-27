#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
printf 'This compatibility entry point now publishes the complete tested ISO package set.\n'
exec "$ROOT_DIR/scripts/publish-testing-image-vm.sh" "$@"
