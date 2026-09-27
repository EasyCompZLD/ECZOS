#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'Debian 13 (trixie) is required.\n' >&2; exit 2;
}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.1}
BUNDLE_DIR="$RELEASE_DIR/packages"

"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/verify-release-0.1.1.sh"
"$ROOT_DIR/scripts/configure-freeoffice-repository-vm.sh"
"$ROOT_DIR/scripts/prepare-image-packages-vm.sh"

install -d -m 2775 "$RELEASE_DIR" "$BUNDLE_DIR"
find "$BUNDLE_DIR" -maxdepth 1 -type f \( -name '*.deb' -o -name 'SHA256SUMS' \) -delete
install -m 0644 "$ROOT_DIR"/image/config/packages.chroot/*.deb "$BUNDLE_DIR/"
(cd "$BUNDLE_DIR" && sha256sum ./*.deb > SHA256SUMS && sha256sum --check SHA256SUMS)

for changelog in "$ROOT_DIR"/packages/eczos-*/debian/changelog; do
    package_dir=${changelog%/debian/changelog}
    package=$(basename "$package_dir")
    version=$(dpkg-parsechangelog -l"$changelog" -S Version)
    compgen -G "$BUNDLE_DIR/${package}_${version}_*.deb" >/dev/null || {
        printf 'Release bundle is missing %s %s.\n' "$package" "$version" >&2
        exit 1
    }
done

printf 'Release package bundle ready: %s\n' "$BUNDLE_DIR"
