#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run this installed-package smoke test as root on the test host.\n' >&2
    exit 2
fi

dpkg-query -W -f='${Status}\n' eczos-release | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-info
test -s /usr/lib/eczos/release/eczos-release
grep -Fx 'ECZOS_BASE_ID=debian' /usr/lib/eczos/release/eczos-release
/usr/bin/eczos-info | grep -Fx 'ECZOS Development'
grep -Fx 'ID=debian' /etc/os-release
dpkg --audit
apt-get check

printf 'eczos-release installed-package smoke test passed\n'
