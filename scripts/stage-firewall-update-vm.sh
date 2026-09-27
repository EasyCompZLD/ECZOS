#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
# shellcheck disable=SC1091
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'Debian 13 (trixie) is required.\n' >&2; exit 2;
}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"
PACKAGES=(eczos-firewall eczos-network-optical eczos-desktop)
SSH_WAS_ENABLED=false
if systemctl is-enabled --quiet ssh.service 2>/dev/null || \
   systemctl is-enabled --quiet ssh.socket 2>/dev/null; then
    SSH_WAS_ENABLED=true
fi

export DEBIAN_FRONTEND=noninteractive
bash "$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
bash "$ROOT_DIR/scripts/verify-source.sh"

debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm; do
        if [[ -f "$package_dir/debian/$maintainer_script" ]]; then
            chmod 0755 "$package_dir/debian/$maintainer_script"
        fi
    done
    for executable_dir in bin lib; do
        if [[ -d "$package_dir/$executable_dir" ]]; then
            find "$package_dir/$executable_dir" -type f -exec chmod 0755 {} +
        fi
    done
    for data_dir in applications config firewalld polkit systemd; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ $architecture == all ]] || architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
    deb="$ROOT_DIR/packages/${package}_${version}_${architecture}.deb"
    test -s "$deb"
    debs+=("$deb")
done

apt-get install -y "${debs[@]}"
bash "$ROOT_DIR/tests/smoke/firewall-package.sh"
bash "$ROOT_DIR/tests/smoke/network-optical-package.sh"
bash "$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

if $SSH_WAS_ENABLED; then
    firewall-cmd --zone=eczos-public --query-service=ssh >/dev/null || {
        printf 'SSH was enabled before the update but is not allowed by the firewall.\n' >&2
        exit 1
    }
fi

for deb in "${debs[@]}"; do
    package=$(dpkg-deb -f "$deb" Package)
    find "$STAGING_DIR" -maxdepth 1 -type f -name "${package}_*.deb" -delete
    install -m 0644 "$deb" "$STAGING_DIR/"
done

printf 'ECZOS firewall update installed, verified and staged.\n'
printf 'Active zone: %s\n' "$(firewall-cmd --get-default-zone)"
printf 'Allowed services: %s\n' "$(firewall-cmd --zone=eczos-public --list-services)"
