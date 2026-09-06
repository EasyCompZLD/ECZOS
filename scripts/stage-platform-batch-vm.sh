#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 test host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

if ! dpkg-query -W -f='${Status}\n' wine32:i386 2>/dev/null | \
    grep -Fx 'install ok installed' >/dev/null; then
    printf 'Run ./scripts/enable-windows-runtime-vm.sh first.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$ROOT_DIR/packages"
TEMP_DIR=$(mktemp -d /tmp/eczos-platform-batch.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

PACKAGES=(eczos-branding eczos-sddm-theme eczos-plymouth-theme eczos-desktop-defaults eczos-release eczos-windows-core eczos-gaming-core eczos-platform-tools eczos-desktop-apps eczos-desktop)
INSTALL_FILES=()

for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm; do
        if [[ -f "$package_dir/debian/$maintainer_script" ]]; then
            chmod 0755 "$package_dir/debian/$maintainer_script"
        fi
    done
    if [[ -d "$package_dir/bin" ]]; then
        find "$package_dir/bin" -type f -exec chmod 0755 {} +
    fi
    if [[ -d "$package_dir/lib" ]]; then
        find "$package_dir/lib" -type f -exec chmod 0755 {} +
    fi
    for data_dir in applications assets config product release runtime-definitions theme xdg; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    package_arch=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    if [[ "$package_arch" != all ]]; then
        package_arch=$(dpkg-architecture -qDEB_HOST_ARCH)
    fi
    built="$OUTPUT_DIR/${package}_${version}_${package_arch}.deb"
    test -f "$built"
    staged="$TEMP_DIR/${package}.deb"
    install -m 0644 "$built" "$staged"
    INSTALL_FILES+=("$staged")
done

lintian "${INSTALL_FILES[@]}" || true
apt-get install -y "${INSTALL_FILES[@]}"
"$ROOT_DIR/tests/smoke/branding-package.sh"
"$ROOT_DIR/tests/smoke/sddm-theme-package.sh"
"$ROOT_DIR/tests/smoke/plymouth-theme-package.sh"
"$ROOT_DIR/tests/smoke/desktop-defaults-package.sh"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/windows-core-package.sh"
"$ROOT_DIR/tests/smoke/gaming-core-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
"$ROOT_DIR/tests/smoke/desktop-apps-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"
update-grub

printf '\nECZOS platform batch installed successfully.\n'
printf 'Log out and back in once to apply menu, desktop and lock-screen branding.\n'
