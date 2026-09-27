#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.1}
BUNDLE_DIR="$RELEASE_DIR/packages"
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
PRIMARY_TARGET=${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}

# Building the ISO requires root, while the signing key, GPG agent and local
# repository belong to the development account. Make standalone publication
# as safe as the combined finalizer by dropping privileges automatically.
if [[ $(id -u) -eq 0 ]]; then
    repository_owner=$(stat -c '%U' "$REPOSITORY_DIR")
    if [[ $repository_owner != root ]]; then
        chmod a+rx "$ROOT_DIR/scripts" \
            "$ROOT_DIR/scripts/publish-release-0.1.1-vm.sh" \
            "$ROOT_DIR/scripts/verify-release-0.1.1.sh" \
            "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
            "$ROOT_DIR/scripts/generate-eczos-repository-web.py" \
            "$ROOT_DIR/scripts/publish-eczos-repository.sh"
        exec runuser -u "$repository_owner" -- env \
            GNUPGHOME=/srv/eczos-repository-secrets/gnupg \
            ECZOS_GPG_PASSPHRASE_FILE=/srv/eczos-repository-secrets/repository-signing-passphrase \
            ECZOS_SSH_PASSWORD_FILE=/srv/eczos-repository-secrets/virtualmin-password \
            ECZOS_SSH_OPTIONS='-p 222 -l codex@repo.easycomp.cloud' \
            ECZOS_RELEASE_DIR="$RELEASE_DIR" \
            ECZOS_REPOSITORY_DIR="$REPOSITORY_DIR" \
            ECZOS_REPOSITORY_TARGET="$PRIMARY_TARGET" \
            ECZOS_REPOSITORY_MIRROR_TARGET="${ECZOS_REPOSITORY_MIRROR_TARGET:-}" \
            bash "$0"
    fi
fi

"$ROOT_DIR/scripts/verify-release-0.1.1.sh"
[[ -s "$BUNDLE_DIR/SHA256SUMS" ]] || {
    printf 'Build the release package bundle first.\n' >&2; exit 1;
}
(cd "$BUNDLE_DIR" && sha256sum --check SHA256SUMS)

mapfile -t release_packages < <(find "$BUNDLE_DIR" -maxdepth 1 -type f \
    -name 'eczos-*.deb' -print | sort)
[[ ${#release_packages[@]} -eq 19 ]] || {
    printf 'Expected 19 ECZOS packages, found %d.\n' "${#release_packages[@]}" >&2
    exit 1
}

export GNUPGHOME=${GNUPGHOME:-/srv/eczos-repository-secrets/gnupg}
export ECZOS_GPG_PASSPHRASE_FILE=${ECZOS_GPG_PASSPHRASE_FILE:-/srv/eczos-repository-secrets/repository-signing-passphrase}
export ECZOS_SSH_PASSWORD_FILE=${ECZOS_SSH_PASSWORD_FILE:-/srv/eczos-repository-secrets/virtualmin-password}
export ECZOS_SSH_OPTIONS=${ECZOS_SSH_OPTIONS:--p 222 -l codex@repo.easycomp.cloud}

"$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
    "$REPOSITORY_DIR" trixie "${release_packages[@]}"
"$ROOT_DIR/scripts/generate-eczos-repository-web.py" \
    "$REPOSITORY_DIR" "$RELEASE_DIR" --version 0.1.1 --published 2026-09-27
"$ROOT_DIR/scripts/publish-eczos-repository.sh" \
    "$REPOSITORY_DIR" "$PRIMARY_TARGET" "${ECZOS_REPOSITORY_MIRROR_TARGET:-}"

printf 'ECZOS 0.1.1 packages are published in the stable repository.\n'
