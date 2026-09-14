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
grep -Fx 'PRETTY_NAME="ECZOS Development 0.1"' /etc/os-release
grep -Fx 'ID=debian' /etc/os-release
grep -Fx 'LOGO=eczos-start' /etc/os-release
grep -Fx 'LogoPath=eczos-start' /etc/xdg/kcm-about-distrorc
grep -Fx 'Version=Development 0.1' /etc/xdg/kcm-about-distrorc
test -e /etc/xdg/kcm-about-distrorc.debian
test "$(dpkg-divert --listpackage /etc/xdg/kcm-about-distrorc)" = eczos-release
grep -Fx 'GRUB_DISTRIBUTOR=ECZOS' /etc/default/grub.d/80-eczos-release.cfg
grep -Fx 'GRUB_BACKGROUND=/usr/share/eczos/branding/wallpapers/eczoswallpaper-dark.png' \
    /etc/default/grub.d/80-eczos-release.cfg
grep -Fq 'ECZOS Development 0.1' /etc/issue
grep -Fx 'ECZOS Development 0.1' /etc/issue.net
grep -Fq 'ECZOS Development by EasyComp Zeeland.' /etc/motd
test -e /etc/os-release.debian
for path in issue issue.net motd; do
    test -e "/etc/$path.debian"
    test "$(dpkg-divert --listpackage "/etc/$path")" = eczos-release
done
dpkg --audit
apt-get check

printf 'eczos-release installed-package smoke test passed\n'
