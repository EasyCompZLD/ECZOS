#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASES_DIR=${ECZOS_RELEASES_DIR:-$ROOT_DIR/Build/Releases}
UPLOAD_ROOT=${ECZOS_GITHUB_UPLOAD_DIR:-$ROOT_DIR/Build/GitHub/UPLOAD-THIS-TO-GITHUB}
VERSION=${1:-}
QUIET=${ECZOS_GITHUB_UPLOAD_QUIET:-0}

if [[ -z "$VERSION" ]]; then
    VERSION=$(find "$RELEASES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null \
        | awk -F. 'NF == 3 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ {print}' \
        | sort -t. -k1,1n -k2,2n -k3,3n \
        | tail -n 1)
fi

[[ -n "$VERSION" ]] || {
    [[ "$QUIET" == 1 ]] || printf 'No ECZOS release directory was found in %s.\n' "$RELEASES_DIR" >&2
    exit 0
}

SOURCE_DIR="$RELEASES_DIR/$VERSION"
IMAGE_NAME="ECZOS-$VERSION-amd64.iso"
NOTES="$SOURCE_DIR/RELEASE-NOTES.md"
CHECKSUM="$SOURCE_DIR/$IMAGE_NAME.sha256"

for required in "$NOTES" "$CHECKSUM"; do
    [[ -s "$required" ]] || {
        [[ "$QUIET" == 1 ]] || printf 'GitHub upload source is missing: %s\n' "$required" >&2
        exit 1
    }
done

checksum_value=$(awk 'NR == 1 {print tolower($1)}' "$CHECKSUM")
checksum_name=$(awk 'NR == 1 {print $2}' "$CHECKSUM")
[[ "$checksum_value" =~ ^[0-9a-f]{64}$ && "$checksum_name" == "$IMAGE_NAME" ]] || {
    printf 'Invalid checksum file: %s\n' "$CHECKSUM" >&2
    exit 1
}

install -d -m 0755 "$UPLOAD_ROOT"
install -m 0644 "$NOTES" "$UPLOAD_ROOT/RELEASE-NOTES.md"
install -m 0644 "$CHECKSUM" "$UPLOAD_ROOT/$IMAGE_NAME.sha256"

commit=unavailable
if git -C "$ROOT_DIR" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit=$(git -C "$ROOT_DIR" rev-parse HEAD)
fi

instructions_tmp="$UPLOAD_ROOT/.README-FIRST.txt.tmp"
cat > "$instructions_tmp" <<EOF
ECZOS GitHub release upload set
================================

Release tag:   v$VERSION
Release title: ECZOS $VERSION
Source commit: $commit

1. Paste the contents of RELEASE-NOTES.md into the GitHub release description.
2. Upload $IMAGE_NAME.sha256 as the release asset.
3. Do NOT upload the ISO: GitHub's per-file limit is 2 GiB.
4. The official ISO remains available at:
   https://repo.easycomp.cloud/eczos/images/$IMAGE_NAME

Every file in this directory is safe to upload to the GitHub release.
Passwords, signing keys, the ISO and build caches are never copied here.
EOF
chmod 0644 "$instructions_tmp"
mv -f "$instructions_tmp" "$UPLOAD_ROOT/README-FIRST.txt"

printf '%s\n' "$VERSION" > "$UPLOAD_ROOT/RELEASE-VERSION.txt"
chmod 0644 "$UPLOAD_ROOT/RELEASE-VERSION.txt"

if [[ "$QUIET" != 1 ]]; then
    printf 'GitHub upload directory refreshed: %s\n' "$UPLOAD_ROOT"
fi
