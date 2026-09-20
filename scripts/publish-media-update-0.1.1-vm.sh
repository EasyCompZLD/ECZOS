#!/usr/bin/env bash
set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
RELEASE_010=${ECZOS_RELEASE_010_DIR:-/srv/eczos-releases/0.1.0}
UPDATE_DIR=${ECZOS_UPDATE_DIR:-/srv/eczos-releases/0.1.1/packages}
PACKAGES=(eczos-platform-tools eczos-recovery-media)

if [[ ${1:-} == --publish-only ]]; then
    mapfile -t package_files < <(find "$UPDATE_DIR" -maxdepth 1 -type f -name 'eczos-*_0.1.1_*.deb' -print | sort)
    [[ ${#package_files[@]} -eq 2 ]] || {
        printf 'Expected two ECZOS 0.1.1 update packages.\n' >&2; exit 1;
    }
    export GNUPGHOME=${GNUPGHOME:-/srv/eczos-repository-secrets/gnupg}
    export ECZOS_GPG_PASSPHRASE_FILE=${ECZOS_GPG_PASSPHRASE_FILE:-/srv/eczos-repository-secrets/repository-signing-passphrase}
    export ECZOS_SSH_PASSWORD_FILE=${ECZOS_SSH_PASSWORD_FILE:-/srv/eczos-repository-secrets/virtualmin-password}
    export ECZOS_SSH_OPTIONS=${ECZOS_SSH_OPTIONS:--p 222 -l codex@repo.easycomp.cloud}
    "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" "$REPOSITORY_DIR" trixie "${package_files[@]}"
    "$ROOT_DIR/scripts/generate-eczos-repository-web.py" "$REPOSITORY_DIR" "$RELEASE_010" \
        --version 0.1.0 --published 2026-09-20
    "$ROOT_DIR/scripts/publish-eczos-repository.sh" "$REPOSITORY_DIR" "${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}"
    printf 'ECZOS Media Creator 0.1.1 update and release catalogue published.\n'
    exit 0
fi

[[ $# -eq 0 ]] || { printf 'Usage: %s [--publish-only]\n' "$0" >&2; exit 2; }
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || exit 2
"$ROOT_DIR/scripts/verify-source.sh"
install -d -m 2775 "$UPDATE_DIR"
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    find "$package_dir"/bin "$package_dir"/lib -type f -exec chmod 0755 {} + 2>/dev/null || true
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    architecture=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ $architecture == all ]] || architecture=$(dpkg-architecture -qDEB_HOST_ARCH)
    built="$ROOT_DIR/packages/${package}_${version}_${architecture}.deb"
    test -s "$built"
    install -m 0644 "$built" "$UPDATE_DIR/"
done
(cd "$UPDATE_DIR" && sha256sum ./*.deb > SHA256SUMS && sha256sum --check SHA256SUMS)
repository_user=$(stat -c '%U' "$REPOSITORY_DIR")
runuser -u "$repository_user" -- bash "$0" --publish-only
