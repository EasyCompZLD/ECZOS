#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY_DIR=${1:-}
PRIMARY_TARGET=${2:-}
MIRROR_TARGET=${3:-}

if [[ -z "$REPOSITORY_DIR" || -z "$PRIMARY_TARGET" ]]; then
    printf 'Usage: %s REPOSITORY_DIR USER@HOST:/ABSOLUTE/ECZOS/PATH [MIRROR_TARGET]\n' "$0" >&2
    exit 2
fi
for required in \
    "$REPOSITORY_DIR/dists/trixie/InRelease" \
    "$REPOSITORY_DIR/dists/trixie-testing/InRelease" \
    "$REPOSITORY_DIR/keys/eczos-archive-keyring.gpg" \
    "$REPOSITORY_DIR/releases.json"; do
    [[ -s "$required" ]] || {
        printf 'Repository is incomplete: %s\n' "$required" >&2
        exit 1
    }
done
command -v rsync >/dev/null 2>&1 || {
    printf 'rsync is required.\n' >&2
    exit 1
}

if [[ -n "${ECZOS_SSH_PASSWORD_FILE:-}" ]]; then
    [[ -s "$ECZOS_SSH_PASSWORD_FILE" ]] || {
        printf 'SSH password file is missing or empty: %s\n' "$ECZOS_SSH_PASSWORD_FILE" >&2
        exit 1
    }
    command -v sshpass >/dev/null 2>&1 || {
        printf 'sshpass is required when ECZOS_SSH_PASSWORD_FILE is set.\n' >&2
        exit 1
    }
    RSYNC_RSH="sshpass -f $ECZOS_SSH_PASSWORD_FILE ssh -o StrictHostKeyChecking=accept-new ${ECZOS_SSH_OPTIONS:-}"
    export RSYNC_RSH
fi

publish_target() {
    local target=$1
    # Publish immutable package payloads first and signed indices last. Old pool
    # files remain available so an update started during publication cannot lose
    # a package referenced by the previous InRelease file.
    rsync -a --chmod=D755,F644 "$REPOSITORY_DIR/pool/" "$target/pool/"
    rsync -a --chmod=D755,F644 "$REPOSITORY_DIR/keys/" "$target/keys/"
    rsync -a --chmod=D755,F644 "$REPOSITORY_DIR/images/" "$target/images/"
    rsync -a --chmod=D755,F644 "$REPOSITORY_DIR/releases.json" "$target/releases.json"
    rsync -a --chmod=D755,F644 "$REPOSITORY_DIR/index.html" "$target/index.html"
    rsync -a --delete-delay --chmod=D755,F644 \
        "$REPOSITORY_DIR/dists/" "$target/dists/"
}

publish_target "$PRIMARY_TARGET"
if [[ -n "$MIRROR_TARGET" ]]; then
    publish_target "$MIRROR_TARGET"
fi

printf 'Published the signed ECZOS repository.\n'
