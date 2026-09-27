#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || exit 2
dpkg-query -W -f='${Status}\n' eczos-network-optical | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-network-optical
test -x /usr/lib/eczos-network-optical/helper
grep -Fq 'eczos-network-optical' /usr/lib/eczos-network-optical/helper
grep -Fq 'firewall-offline-cmd' /usr/lib/eczos-network-optical/helper
test -x /usr/lib/eczos-network-optical/guard
test -s /usr/share/polkit-1/actions/org.eczos.networkoptical.policy
test -s /usr/lib/systemd/system/eczos-network-optical-guard.service
python3 -m py_compile /usr/bin/eczos-network-optical /usr/lib/eczos-network-optical/helper /usr/lib/eczos-network-optical/guard
/usr/bin/eczos-network-optical status --json | jq -e '.schema == 1 and (.local | type == "array") and (.network | type == "array")' >/dev/null
grep -Fq 'org.eczos.networkoptical.manage' /usr/share/polkit-1/actions/org.eczos.networkoptical.policy
grep -Fq 'generate_node_acls' /usr/lib/eczos-network-optical/guard
grep -Fq 'tpg.set_attribute("authentication", "0")' /usr/lib/eczos-network-optical/helper
grep -Fq 'share rollback failed' /usr/lib/eczos-network-optical/helper
grep -Fq 'shlex.split' /usr/bin/eczos-network-optical
dpkg --audit
apt-get check
printf 'eczos-network-optical installed-package smoke test passed\n'
