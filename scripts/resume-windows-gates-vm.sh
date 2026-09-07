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

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEMP_DIR=$(mktemp -d /tmp/eczos-windows-gates.XXXXXX)
chmod 0755 "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

for package in eczos-release eczos-windows-core eczos-desktop; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    if [[ -d "$package_dir/bin" ]]; then
        find "$package_dir/bin" -type f -exec chmod 0755 {} +
    fi
    if [[ -d "$package_dir/lib" ]]; then
        find "$package_dir/lib" -type f -exec chmod 0755 {} +
    fi
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ "$architecture" = all ]] || architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
    built="$ROOT_DIR/packages/${package}_${version}_${architecture}.deb"
    test -f "$built"
    install -m 0644 "$built" "$TEMP_DIR/$package.deb"
done

apt-get install -y "$TEMP_DIR/eczos-release.deb" "$TEMP_DIR/eczos-windows-core.deb" "$TEMP_DIR/eczos-desktop.deb"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/windows-core-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"
"$ROOT_DIR/scripts/test-windows-msi-lifecycle-vm.sh"
"$ROOT_DIR/scripts/audit-visible-branding-vm.sh"
update-grub

printf '\nECZ Windows MSI, icon, repair and removal gates passed.\n'
