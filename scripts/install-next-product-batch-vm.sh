#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
head -n1 "$ROOT_DIR/packages/eczos-windows-core/debian/changelog" | grep -Fq '0.1.0~dev11' || {
    printf 'This is not the current ECZOS source batch. Synchronize /srv/eczos first.\n' >&2
    exit 1
}

"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"
apt-get install -y bubblewrap icoutils wixl xvfb xauth
"$ROOT_DIR/scripts/stage-platform-batch-vm.sh"
"$ROOT_DIR/scripts/test-windows-msi-lifecycle-vm.sh"
"$ROOT_DIR/scripts/audit-visible-branding-vm.sh"

printf '\nECZOS FreeOffice, MSI, icon, repair and branding-audit batch passed.\n'
printf 'Log out and back in, then open TextMaker once for the visual FreeOffice check.\n'
