#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || exit 2
dpkg-query -W -f='${Status}\n' eczos-installer | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-installer
test -x /usr/bin/eczos-add-installer-icon
sh -n /usr/bin/eczos-installer
sh -n /usr/bin/eczos-add-installer-icon
test -s /usr/share/applications/org.eczos.Installer.desktop
test -s /usr/share/calamares/branding/eczos/branding.desc
test -e /usr/share/calamares/branding/eczos/eczos-logo.png
test -e /usr/share/calamares/branding/eczos/eczos-welcome.png
grep -Fx 'Name=ECZOS installeren' /usr/share/applications/org.eczos.Installer.desktop
grep -Fx '    shortProductName: ECZOS' /usr/share/calamares/branding/eczos/branding.desc
if grep -REi 'Debian GNU/Linux|Install Debian' \
    /usr/share/calamares/branding/eczos \
    /usr/share/applications/org.eczos.Installer.desktop; then
    printf 'Visible Debian installer branding found in ECZOS-owned files.\n' >&2
    exit 1
fi
dpkg --audit
apt-get check
printf 'eczos-installer installed-package smoke test passed\n'
