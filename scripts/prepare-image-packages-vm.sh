#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the dedicated Debian 13 build host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$ROOT_DIR/packages"
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"
MANIFEST_DIR="$ROOT_DIR/image/.build/packages"
PACKAGES=(
    eczos-branding
    eczos-sddm-theme
    eczos-plymouth-theme
    eczos-desktop-defaults
    eczos-release
    eczos-windows-core
    eczos-gaming-core
    eczos-platform-tools
    eczos-desktop-apps
    eczos-desktop
)

mkdir -p "$STAGING_DIR" "$MANIFEST_DIR"
find "$STAGING_DIR" -maxdepth 1 -type f -name 'eczos-*.deb' -delete

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
    if [[ ! -f "$built" ]]; then
        printf 'Expected package output is missing: %s\n' "$built" >&2
        exit 1
    fi
    dpkg-deb --info "$built" >/dev/null
    install -m 0644 "$built" "$STAGING_DIR/"
done

lintian "$STAGING_DIR"/*.deb || true
(cd "$STAGING_DIR" && sha256sum ./*.deb > "$MANIFEST_DIR/SHA256SUMS")

printf 'Staged %s ECZOS packages for live-build.\n' "${#PACKAGES[@]}"
