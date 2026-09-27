#!/usr/bin/env bash
set -Eeuo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2
    exit 2
fi
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-windows-core eczos-platform-tools)
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"

for command in cmake dpkg-buildpackage dpkg-parsechangelog jq; do
    command -v "$command" >/dev/null 2>&1 || {
        printf 'Missing build command: %s\n' "$command" >&2
        printf 'Run scripts/stage-settings-gaming-batch-vm.sh once to install all build dependencies.\n' >&2
        exit 69
    }
done

bash "$ROOT_DIR/scripts/verify-source.sh"
declare -a debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm; do
        [[ ! -f "$package_dir/debian/$maintainer_script" ]] || \
            chmod 0755 "$package_dir/debian/$maintainer_script"
    done
    for executable_dir in bin lib; do
        [[ -d "$package_dir/$executable_dir" ]] || continue
        find "$package_dir/$executable_dir" -type f -exec chmod 0755 {} +
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    package_arch=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ "$package_arch" = all ]] || package_arch=$(dpkg-architecture -qDEB_HOST_ARCH)
    deb="$ROOT_DIR/packages/${package}_${version}_${package_arch}.deb"
    [[ -s "$deb" ]] || { printf 'Expected package was not built: %s\n' "$deb" >&2; exit 1; }
    debs+=("$deb")
    find "$STAGING_DIR" -maxdepth 1 -type f -name "${package}_*.deb" -delete
    install -m 0644 "$deb" "$STAGING_DIR/"
done

apt-get install -y "${debs[@]}"
bash "$ROOT_DIR/tests/smoke/windows-core-package.sh"
bash "$ROOT_DIR/tests/smoke/platform-tools-package.sh"

printf '\nECZ Windows production UX batch passed.\n'
printf 'The validated packages were also staged for the next ISO.\n'
printf 'Installed packages:\n'
printf '  %s\n' "${debs[@]}"
