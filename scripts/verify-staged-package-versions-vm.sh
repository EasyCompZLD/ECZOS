#!/usr/bin/env bash
set -Eeuo pipefail

STAGING_DIR=${1:-}
[[ -d "$STAGING_DIR" ]] || {
    printf 'Usage: %s STAGED-PACKAGE-DIRECTORY\n' "$0" >&2
    exit 2
}
for command_name in apt-cache dpkg dpkg-deb; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing version-verification command: %s\n' "$command_name" >&2
        exit 1
    }
done

checked=0
for package_file in "$STAGING_DIR"/eczos-*.deb; do
    [[ -f "$package_file" ]] || continue
    package=$(dpkg-deb -f "$package_file" Package)
    staged_version=$(dpkg-deb -f "$package_file" Version)
    newest_repository_version=''
    while read -r repository_version; do
        [[ -n "$repository_version" ]] || continue
        if [[ -z "$newest_repository_version" ]] || dpkg --compare-versions "$repository_version" gt "$newest_repository_version"; then
            newest_repository_version=$repository_version
        fi
    done < <(apt-cache madison "$package" 2>/dev/null | awk '{print $3}')
    if [[ -n "$newest_repository_version" ]] && ! dpkg --compare-versions "$staged_version" gt "$newest_repository_version"; then
        printf 'Refusing non-unique ISO package: %s %s is not newer than repository version %s.\n' \
            "$package" "$staged_version" "$newest_repository_version" >&2
        exit 1
    fi
    checked=$((checked + 1))
done
(( checked > 0 )) || { printf 'No staged ECZOS packages found in %s.\n' "$STAGING_DIR" >&2; exit 1; }
printf 'Verified %d staged ECZOS package version(s) as unique and newer than configured repositories.\n' "$checked"
