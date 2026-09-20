#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.0}
BUNDLE_DIR="$RELEASE_DIR/packages"
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
PRIMARY_TARGET=${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}

"$ROOT_DIR/scripts/verify-release-0.1.0.sh"
[[ -s "$BUNDLE_DIR/SHA256SUMS" ]] || {
    printf 'Build the release package bundle first.\n' >&2; exit 1;
}
(cd "$BUNDLE_DIR" && sha256sum --check SHA256SUMS)

mapfile -t release_packages < <(find "$BUNDLE_DIR" -maxdepth 1 -type f \
    -name 'eczos-*.deb' -print | sort)
[[ ${#release_packages[@]} -eq 15 ]] || {
    printf 'Expected 15 ECZOS packages, found %d.\n' "${#release_packages[@]}" >&2
    exit 1
}

export GNUPGHOME=${GNUPGHOME:-/srv/eczos-repository-secrets/gnupg}
export ECZOS_GPG_PASSPHRASE_FILE=${ECZOS_GPG_PASSPHRASE_FILE:-/srv/eczos-repository-secrets/repository-signing-passphrase}
export ECZOS_SSH_PASSWORD_FILE=${ECZOS_SSH_PASSWORD_FILE:-/srv/eczos-repository-secrets/virtualmin-password}
export ECZOS_SSH_OPTIONS=${ECZOS_SSH_OPTIONS:--p 222 -l codex@repo.easycomp.cloud}

"$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
    "$REPOSITORY_DIR" trixie "${release_packages[@]}"
"$ROOT_DIR/scripts/publish-eczos-repository.sh" \
    "$REPOSITORY_DIR" "$PRIMARY_TARGET" "${ECZOS_REPOSITORY_MIRROR_TARGET:-}"

printf 'ECZOS 0.1.0 packages are published in the stable repository.\n'
