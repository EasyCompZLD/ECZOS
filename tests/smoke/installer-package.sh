#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || exit 2
dpkg-query -W -f='${Status}\n' eczos-installer | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-installer
test -x /usr/bin/eczos-add-installer-icon
sh -n /usr/bin/eczos-installer
sh -n /usr/bin/eczos-add-installer-icon
test -x /var/lib/dpkg/info/eczos-installer.prerm
sh -n /var/lib/dpkg/info/eczos-installer.prerm
test -s /usr/share/applications/org.eczos.Installer.desktop
test -s /usr/share/eczos/installer/calamares/settings.conf
test -s /usr/share/eczos/installer/calamares/modules/bootloader.conf
test -s /usr/share/eczos/installer/calamares/modules/packages.conf
test -s /usr/share/eczos/installer/calamares/modules/users.conf
test -s /usr/share/calamares/branding/eczos/branding.desc
test -e /usr/share/calamares/branding/eczos/eczos-logo.png
test -e /usr/share/calamares/branding/eczos/eczos-welcome.png
grep -Fx 'Name=Install ECZOS' /usr/share/applications/org.eczos.Installer.desktop
grep -Fx 'Name[nl]=ECZOS installeren' /usr/share/applications/org.eczos.Installer.desktop
grep -Fx 'branding: eczos' /usr/share/eczos/installer/calamares/settings.conf
grep -Fq 'calamares --config /usr/share/eczos/installer/calamares' /usr/bin/eczos-installer
grep -Fx '    shortProductName: ECZOS' /usr/share/calamares/branding/eczos/branding.desc
grep -Fx 'welcomeStyleCalamares: false' /usr/share/calamares/branding/eczos/branding.desc
grep -F 'color: "#f2071829"' /usr/share/calamares/branding/eczos/show.qml
grep -F 'qsTr("Your familiar applications")' /usr/share/calamares/branding/eczos/show.qml
grep -F 'qsTr("Safe updates and recovery")' /usr/share/calamares/branding/eczos/show.qml
grep -F 'branding/screenshots/oobe-welcome.png' /usr/share/calamares/branding/eczos/show.qml
grep -F 'branding/screenshots/windows-apps.png' /usr/share/calamares/branding/eczos/show.qml
grep -F 'branding/screenshots/steam-library-content.png' /usr/share/calamares/branding/eczos/show.qml
grep -F 'branding/screenshots/updates.png' /usr/share/calamares/branding/eczos/show.qml
for locale in nl de fr; do
    test -s "/usr/share/calamares/branding/eczos/lang/calamares-eczos_${locale}.qm"
done
if grep -REi 'Debian GNU/Linux|Install Debian' \
    /usr/share/calamares/branding/eczos \
    /usr/share/applications/org.eczos.Installer.desktop; then
    printf 'Visible Debian installer branding found in ECZOS-owned files.\n' >&2
    exit 1
fi
grep -Fq 'calamares-install-debian.desktop' /usr/bin/eczos-add-installer-icon
grep -Fq 'calamares-install-debian.desktop' /var/lib/dpkg/info/eczos-installer.prerm
dpkg --audit
apt-get check
printf 'eczos-installer installed-package smoke test passed\n'
