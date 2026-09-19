#!/usr/bin/env bash
set -Eeuo pipefail

GNUPGHOME=${GNUPGHOME:-/srv/eczos-repository-secrets/gnupg}
PASSPHRASE_FILE=${ECZOS_GPG_PASSPHRASE_FILE:-/srv/eczos-repository-secrets/repository-signing-passphrase}
PRESET_HELPER=/usr/lib/gnupg/gpg-preset-passphrase

[[ -d "$GNUPGHOME" ]] || {
    printf 'GnuPG home is missing: %s\n' "$GNUPGHOME" >&2
    exit 1
}
[[ -s "$PASSPHRASE_FILE" ]] || {
    printf 'Repository signing passphrase file is missing or empty: %s\n' "$PASSPHRASE_FILE" >&2
    exit 1
}
[[ $(stat -c '%a' "$PASSPHRASE_FILE") == 600 ]] || {
    printf 'Repository signing passphrase file must have mode 600: %s\n' "$PASSPHRASE_FILE" >&2
    exit 1
}
[[ -x "$PRESET_HELPER" ]] || {
    printf 'gpg-preset-passphrase is unavailable: %s\n' "$PRESET_HELPER" >&2
    exit 1
}

agent_config="$GNUPGHOME/gpg-agent.conf"
touch "$agent_config"
chmod 0600 "$agent_config"
if ! grep -qxF 'allow-preset-passphrase' "$agent_config"; then
    printf 'allow-preset-passphrase\n' >> "$agent_config"
    gpgconf --kill gpg-agent
fi
gpgconf --launch gpg-agent

keygrip=$(gpg --batch --with-colons --with-keygrip --list-secret-keys |
    awk -F: '$1 == "grp" {print $10; exit}')
[[ -n "$keygrip" ]] || {
    printf 'No repository signing key is available in %s.\n' "$GNUPGHOME" >&2
    exit 1
}

"$PRESET_HELPER" --preset "$keygrip" < "$PASSPHRASE_FILE"
printf 'ECZOS repository signing key unlocked for this login session.\n'
