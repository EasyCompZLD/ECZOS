#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

KEYRING=/usr/share/keyrings/eczos-archive-keyring.asc
FINGERPRINT=2AF16813F96EF0FE40BD6DAAECC6969C9A9A339F

dpkg-query -W -f='${Status}\n' eczos-archive-keyring | grep -Fx 'install ok installed'
test -s "$KEYRING"
test "$(gpg --batch --show-keys --with-colons "$KEYRING" 2>/dev/null | awk -F: '$1 == "fpr" {print $10; exit}')" = "$FINGERPRINT"

printf 'eczos-archive-keyring installed-package smoke test passed\n'
