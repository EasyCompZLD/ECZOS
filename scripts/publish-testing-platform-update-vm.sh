#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"
RUNUSER=${ECZOS_RUNUSER:-/usr/sbin/runuser}
PACKAGE_NAMES=(eczos-platform-tools eczos-windows-core)

if [[ ${1:-} != --as-repository-owner ]]; then
    [[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
    [[ -x "$RUNUSER" ]] || { printf 'Required command not found: %s\n' "$RUNUSER" >&2; exit 1; }
    [[ -d "$REPOSITORY_DIR" ]] || { printf 'Repository directory not found: %s\n' "$REPOSITORY_DIR" >&2; exit 1; }
    declare -a packages=()
    for package_name in "${PACKAGE_NAMES[@]}"; do
        mapfile -t matches < <(find "$STAGING_DIR" -maxdepth 1 -type f \
            -name "${package_name}_*.deb" -print | sort)
        [[ ${#matches[@]} -eq 1 ]] || {
            printf 'Expected exactly one staged %s package, found %d.\n' \
                "$package_name" "${#matches[@]}" >&2
            exit 1
        }
        actual_name=$(dpkg-deb -f "${matches[0]}" Package)
        [[ "$actual_name" = "$package_name" ]] || {
            printf 'Staged package identity mismatch: %s\n' "${matches[0]}" >&2
            exit 1
        }
        candidate_version=$(dpkg-deb -f "${matches[0]}" Version)
        current_version=$(reprepro --basedir "$REPOSITORY_DIR" list trixie-testing "$package_name" 2>/dev/null |
            awk -v package="$package_name" '$2 == package { print $3; exit }')
        if [[ -n "$current_version" ]] && dpkg --compare-versions "$candidate_version" lt "$current_version"; then
            printf 'Refusing to replace %s %s with older version %s.\n' \
                "$package_name" "$current_version" "$candidate_version" >&2
            exit 1
        fi
        printf 'Validated %s %s (repository: %s).\n' \
            "$package_name" "$candidate_version" "${current_version:-not published}"
        packages+=("${matches[0]}")
    done

    # NAS/macOS working-copy modes must not block the repository owner.
    chmod a+rx "$ROOT_DIR/scripts" \
        "$ROOT_DIR/scripts/publish-testing-platform-update-vm.sh" \
        "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
        "$ROOT_DIR/scripts/publish-eczos-repository.sh"
    owner=$(stat -c '%U' "$REPOSITORY_DIR")
    exec "$RUNUSER" -u "$owner" -- env \
        GNUPGHOME=/srv/eczos-repository-secrets/gnupg \
        ECZOS_GPG_PASSPHRASE_FILE=/srv/eczos-repository-secrets/repository-signing-passphrase \
        ECZOS_SSH_PASSWORD_FILE=/srv/eczos-repository-secrets/virtualmin-password \
        ECZOS_SSH_OPTIONS='-p 222 -l codex@repo.easycomp.cloud' \
        ECZOS_REPOSITORY_DIR="$REPOSITORY_DIR" \
        ECZOS_REPOSITORY_TARGET="${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" \
        ECZOS_REPOSITORY_MIRROR_TARGET="${ECZOS_REPOSITORY_MIRROR_TARGET:-}" \
        bash "$0" --as-repository-owner "${packages[@]}"
fi

shift
[[ $# -eq 2 ]] || { printf 'Expected two validated package paths.\n' >&2; exit 2; }
"$ROOT_DIR/scripts/import-eczos-repository-packages.sh" \
    "$REPOSITORY_DIR" trixie-testing "$@"
"$ROOT_DIR/scripts/publish-eczos-repository.sh" \
    "$REPOSITORY_DIR" "${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" \
    "${ECZOS_REPOSITORY_MIRROR_TARGET:-}"

printf 'Published ECZOS Settings and ECZ Windows updates to trixie-testing.\n'
