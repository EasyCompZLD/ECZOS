#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || exit 2
dpkg-query -W -f='${Status}\n' eczos-firewall | grep -Fx 'install ok installed'
dpkg-query -W -f='${Status}\n' firewalld | grep -Fx 'install ok installed'
dpkg-query -W -f='${Status}\n' plasma-firewall | grep -Fx 'install ok installed'
test -s /usr/lib/firewalld/zones/eczos-public.xml
test -s /usr/lib/firewalld/services/eczos-kde-connect.xml
test -s /usr/lib/firewalld/services/eczos-network-optical.xml
/usr/bin/firewall-offline-cmd --check-config
test "$(/usr/bin/firewall-offline-cmd --get-default-zone)" = eczos-public
/usr/bin/firewall-offline-cmd --zone=eczos-public --query-service=mdns
/usr/bin/firewall-offline-cmd --zone=eczos-public --query-service=eczos-kde-connect
systemctl is-enabled --quiet firewalld.service
if [ -d /run/systemd/system ]; then
    systemctl is-active --quiet firewalld.service
    firewall-cmd --state | grep -Fx running
    firewall-cmd --get-default-zone | grep -Fx eczos-public
fi
dpkg --audit
apt-get check
printf 'eczos-firewall installed-package smoke test passed\n'
