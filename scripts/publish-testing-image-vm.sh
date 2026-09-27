#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
STAGING_DIR="$ROOT_DIR/image/config/packages.chroot"
RELEASE_DIR=${ECZOS_TESTING_RELEASE_DIR:-/srv/eczos-releases/0.1.1-testing}
IMAGE_NAME=ECZOS-0.1.1-testing-amd64.iso
RUNUSER=${ECZOS_RUNUSER:-/usr/sbin/runuser}

if [[ ${1:-} != --as-repository-owner ]]; then
    [[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
    "$ROOT_DIR/scripts/verify-staged-package-versions-vm.sh" "$STAGING_DIR"
    mapfile -t packages < <(find "$STAGING_DIR" -maxdepth 1 -type f -name 'eczos-*.deb' -print | sort)
    [[ ${#packages[@]} -eq 19 ]] || { printf 'Expected 19 staged ECZOS packages, found %d.\n' "${#packages[@]}" >&2; exit 1; }

    latest_iso=''
    while read -r run; do
        candidate=$(find "$run/artifacts" -maxdepth 1 -type f -name '*.iso' -print -quit 2>/dev/null || true)
        if [[ -n "$candidate" ]] && grep -Fq 'Build completed successfully' "$run/build.log"; then
            latest_iso=$candidate
            break
        fi
    done < <(find /srv/eczos-builds -mindepth 1 -maxdepth 1 -type d -name 'run-*' -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)
    [[ -s "$latest_iso" ]] || { printf 'No successful hardware-qualification ISO was found.\n' >&2; exit 1; }
    checksum_file="$latest_iso.sha256"
    [[ -s "$checksum_file" ]] || { printf 'ISO checksum file is missing: %s\n' "$checksum_file" >&2; exit 1; }
    (cd "$(dirname "$latest_iso")" && sha256sum --check "$(basename "$checksum_file")")

    install -d -m 2775 "$RELEASE_DIR/images"
    release_image="$RELEASE_DIR/images/$IMAGE_NAME"
    release_checksum="$release_image.sha256"
    if [[ -s "$release_image" && -s "$release_checksum" ]] && \
       (cd "$RELEASE_DIR/images" && sha256sum --check "$(basename "$release_checksum")"); then
        printf 'Reusing verified release image: %s\n' "$release_image"
    else
        cp --reflink=auto "$latest_iso" "$release_image"
        chmod 0644 "$release_image"
        (cd "$RELEASE_DIR/images" && sha256sum "$IMAGE_NAME" > "$IMAGE_NAME.sha256")
    fi

    logo_source="$ROOT_DIR/packages/eczos-branding/assets/logo/logo-dark.png"
    [[ -s "$logo_source" ]] || { printf 'ECZOS repository logo not found: %s\n' "$logo_source" >&2; exit 1; }
    install -d -m 0755 "$RELEASE_DIR/assets"
    install -m 0644 "$logo_source" "$RELEASE_DIR/assets/eczos-logo-dark.png"
    chmod a+rx "$RELEASE_DIR" "$RELEASE_DIR/assets"

    [[ -d "$REPOSITORY_DIR" ]] || { printf 'Repository directory not found: %s\n' "$REPOSITORY_DIR" >&2; exit 1; }
    [[ -x "$RUNUSER" ]] || { printf 'Required account-switching command not found: %s\n' "$RUNUSER" >&2; exit 1; }
    # The NAS/macOS working copy can present source files as mode 0700.  The
    # repository owner must be able to traverse and read these public scripts
    # after the privilege drop; no secrets are stored below scripts/.
    chmod a+rx "$ROOT_DIR/scripts" \
        "$ROOT_DIR/scripts/publish-testing-image-vm.sh" \
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
        ECZOS_TESTING_RELEASE_DIR="$RELEASE_DIR" \
        ECZOS_REPOSITORY_TARGET="${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" \
        ECZOS_REPOSITORY_MIRROR_TARGET="${ECZOS_REPOSITORY_MIRROR_TARGET:-}" \
        bash "$0" --as-repository-owner
fi

mapfile -t packages < <(find "$STAGING_DIR" -maxdepth 1 -type f -name 'eczos-*.deb' -print | sort)
[[ ${#packages[@]} -eq 19 ]] || { printf 'Expected 19 staged ECZOS packages, found %d.\n' "${#packages[@]}" >&2; exit 1; }
all_packages_present=true
for package_file in "${packages[@]}"; do
    package_name=$(dpkg-deb -f "$package_file" Package)
    package_version=$(dpkg-deb -f "$package_file" Version)
    if ! reprepro --basedir "$REPOSITORY_DIR" list trixie-testing "$package_name" | \
         awk -v package="$package_name" -v version="$package_version" \
             '$2 == package && $3 == version { found=1 } END { exit !found }'; then
        all_packages_present=false
        break
    fi
done
if [[ "$all_packages_present" == true ]]; then
    printf 'All 19 staged ECZOS packages are already present in trixie-testing; reusing them.\n'
else
    "$ROOT_DIR/scripts/import-eczos-repository-packages.sh" "$REPOSITORY_DIR" trixie-testing "${packages[@]}"
fi
"$ROOT_DIR/scripts/generate-eczos-repository-web.py" "$REPOSITORY_DIR" "$RELEASE_DIR" \
    --version 0.1.1 --channel testing --image-name "$IMAGE_NAME" \
    --logo-source "$RELEASE_DIR/assets/eczos-logo-dark.png" --published 2026-09-27
"$ROOT_DIR/scripts/publish-eczos-repository.sh" \
    "$REPOSITORY_DIR" "${ECZOS_REPOSITORY_TARGET:-192.168.1.28:.}" "${ECZOS_REPOSITORY_MIRROR_TARGET:-}"

printf 'Published 19 ECZOS packages to trixie-testing and published %s.\n' "$IMAGE_NAME"
