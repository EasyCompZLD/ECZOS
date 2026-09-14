#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPOSITORY_DIR=${1:-}
SIGNING_FINGERPRINT=${2:-}

if [[ -z "$REPOSITORY_DIR" || -z "$SIGNING_FINGERPRINT" ]]; then
    printf 'Usage: %s REPOSITORY_DIR SIGNING_FINGERPRINT\n' "$0" >&2
    exit 2
fi
if [[ ! "$SIGNING_FINGERPRINT" =~ ^[A-Fa-f0-9]{40}$ ]]; then
    printf 'Use the complete 40-character OpenPGP signing-key fingerprint.\n' >&2
    exit 2
fi
for command in gpg reprepro; do
    command -v "$command" >/dev/null 2>&1 || {
        printf '%s is required. Install reprepro and gnupg first.\n' "$command" >&2
        exit 1
    }
done
gpg --batch --list-secret-keys "$SIGNING_FINGERPRINT" >/dev/null 2>&1 || {
    printf 'The secret signing key is not available in this account.\n' >&2
    exit 1
}

install -d -m 0750 "$REPOSITORY_DIR/conf"
sed "s/@SIGNING_FINGERPRINT@/$SIGNING_FINGERPRINT/g" \
    "$ROOT_DIR/repository/conf/distributions.template" \
    > "$REPOSITORY_DIR/conf/distributions"
chmod 0640 "$REPOSITORY_DIR/conf/distributions"
install -m 0644 "$ROOT_DIR/repository/index.html" "$REPOSITORY_DIR/index.html"
install -d -m 0755 "$REPOSITORY_DIR/keys"
gpg --batch --export "$SIGNING_FINGERPRINT" \
    > "$REPOSITORY_DIR/keys/eczos-archive-keyring.gpg"
chmod 0644 "$REPOSITORY_DIR/keys/eczos-archive-keyring.gpg"

reprepro --basedir "$REPOSITORY_DIR" export trixie
reprepro --basedir "$REPOSITORY_DIR" export trixie-testing

printf 'Initialized signed ECZOS repository: %s\n' "$REPOSITORY_DIR"
printf 'Private signing-key material was not copied into the repository.\n'
