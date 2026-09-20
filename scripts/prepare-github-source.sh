#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TARGET_DIR=${ECZOS_GITHUB_SOURCE_DIR:-$ROOT_DIR/Build/GitHub/ECZOS-SOURCE}
GITHUB_URL=${ECZOS_GITHUB_URL:-https://github.com/EasyCompZLD/ECZOS.git}
QUIET=${ECZOS_GITHUB_UPLOAD_QUIET:-0}

if [[ ! -d "$TARGET_DIR/.git" ]]; then
    [[ ! -e "$TARGET_DIR" ]] || {
        printf 'Refusing to replace non-repository path: %s\n' "$TARGET_DIR" >&2
        exit 1
    }
    install -d -m 0755 "$(dirname "$TARGET_DIR")"
    git clone --no-hardlinks "$ROOT_DIR" "$TARGET_DIR"
    git -C "$TARGET_DIR" remote rename origin workspace
    git -C "$TARGET_DIR" remote add origin "$GITHUB_URL"
fi

[[ "$(git -C "$TARGET_DIR" rev-parse --show-toplevel)" == "$TARGET_DIR" ]] || {
    printf 'Invalid GitHub source repository: %s\n' "$TARGET_DIR" >&2
    exit 1
}

if [[ -n "$(git -C "$TARGET_DIR" status --porcelain --untracked-files=all)" ]]; then
    printf 'GitHub source repository contains local changes; refusing to overwrite them: %s\n' "$TARGET_DIR" >&2
    exit 1
fi

git -C "$TARGET_DIR" remote set-url origin "$GITHUB_URL"
if git -C "$TARGET_DIR" remote get-url workspace >/dev/null 2>&1; then
    git -C "$TARGET_DIR" remote set-url workspace "$ROOT_DIR"
else
    git -C "$TARGET_DIR" remote add workspace "$ROOT_DIR"
fi

git -C "$TARGET_DIR" fetch --quiet --force workspace \
    '+refs/heads/main:refs/remotes/workspace/main' \
    '+refs/tags/*:refs/tags/*'
git -C "$TARGET_DIR" checkout --quiet main
git -C "$TARGET_DIR" reset --quiet --hard refs/remotes/workspace/main
git -C "$TARGET_DIR" config branch.main.remote origin
git -C "$TARGET_DIR" config branch.main.merge refs/heads/main
git -C "$TARGET_DIR" config core.hooksPath /dev/null

if [[ "$QUIET" != 1 ]]; then
    printf 'Safe GitHub source repository refreshed: %s\n' "$TARGET_DIR"
fi
