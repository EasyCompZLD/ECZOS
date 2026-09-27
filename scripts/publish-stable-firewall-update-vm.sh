#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.1}
RUNUSER=${ECZOS_RUNUSER:-/usr/sbin/runuser}
PACKAGE_NAMES=(eczos-firewall eczos-network-optical eczos-desktop)

if [[ ${1:-} != --as-repository-owner ]]; then
    [[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
    [[ -d "$REPOSITORY_DIR" ]] || { printf 'Repository directory not found.\n' >&2; exit 1; }
    packages=()
    for package_name in "${PACKAGE_NAMES[@]}"; do
        mapfile -t matches < <(find "$STAGING_DIR" -maxdepth 1 -type f \
            -name "${package_name}_*.deb" -print | sort)
        [[ ${#matches[@]} -eq 1 ]] || {
            printf 'Expected exactly one staged %s package, found %d.\n' \
                "$package_name" "${#matches[@]}" >&2
            exit 1
        }
        candidate_version=$(dpkg-deb -f "${matches[0]}" Version)
        current_version=$(reprepro --basedir "$REPOSITORY_DIR" list trixie "$package_name" 2>/dev/null |
            awk -v package="$package_name" '$2 == package { print $3; exit }')
        if [[ -n "$current_version" ]] && \
           ! dpkg --compare-versions "$candidate_version" gt "$current_version"; then
            printf 'Refusing non-newer %s %s (repository: %s).\n' \
                "$package_name" "$candidate_version" "$current_version" >&2
            exit 1
        fi
        packages+=("${matches[0]}")
    done

    chmod a+rx "$ROOT_DIR/scripts" \
        "$ROOT_DIR/scripts/publish-stable-firewall-update-vm.sh" \
        "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
        "$ROOT_DIR/scripts/generate-eczos-repository-web.py" \
        "$ROOT_DIR/scripts/publish-eczos-repository.sh"
    owner=$(stat -c '%U' "$REPOSITORY_DIR")
    exec "$RUNUSER" -u "$owner" -- env \
        GNUPGHOME=/srv/eczos-repository-secrets/gnupg \
        ECZOS_GPG_PASSPHRASE_FILE=/srv/eczos-repository-secrets/repository-signing-passphrase \
        ECZOS_SSH_PASSWORD_FILE=/srv/eczos-repository-secrets/virtualmin-password \
        ECZOS_SSH_OPTIONS='-p 222 -l codex@repo.easycomp.cloud' \
        ECZOS_REPOSITORY_DIR="$REPOSITORY_DIR" \
        ECZOS_RELEASE_DIR="$RELEASE_DIR" \
        ECZOS_REPOSITORY_TARGET="${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" \
        ECZOS_REPOSITORY_MIRROR_TARGET="${ECZOS_REPOSITORY_MIRROR_TARGET:-}" \
        bash "$0" --as-repository-owner "${packages[@]}"
fi

shift
[[ $# -eq 3 ]] || { printf 'Expected three validated package paths.\n' >&2; exit 2; }
bash "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
    "$REPOSITORY_DIR" trixie "$@"
"$ROOT_DIR/scripts/generate-eczos-repository-web.py" \
    "$REPOSITORY_DIR" "$RELEASE_DIR" --version 0.1.1 --published 2026-09-27
bash "$ROOT_DIR/scripts/publish-eczos-repository.sh" \
    "$REPOSITORY_DIR" "${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" \
    "${ECZOS_REPOSITORY_MIRROR_TARGET:-}"

printf 'Published the ECZOS firewall update to the stable repository.\n'
