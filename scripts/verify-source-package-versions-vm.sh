#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
for command_name in apt-cache dpkg dpkg-parsechangelog; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing source-version verification command: %s\n' "$command_name" >&2
        exit 1
    }
done

checked=0
for changelog in "$ROOT_DIR"/packages/eczos-*/debian/changelog; do
    package=${changelog%/debian/changelog}
    package=${package##*/}
    source_version=$(dpkg-parsechangelog -l"$changelog" -S Version)
    newest_repository_version=''
    while read -r repository_version; do
        [[ -n "$repository_version" ]] || continue
        if [[ -z "$newest_repository_version" ]] || dpkg --compare-versions "$repository_version" gt "$newest_repository_version"; then
            newest_repository_version=$repository_version
        fi
    done < <(apt-cache madison "$package" 2>/dev/null | awk '{print $3}')
    if [[ -n "$newest_repository_version" ]] && ! dpkg --compare-versions "$source_version" gt "$newest_repository_version"; then
        printf 'Refusing reused package version: %s source version %s is not newer than repository version %s.\n' \
            "$package" "$source_version" "$newest_repository_version" >&2
        exit 1
    fi
    checked=$((checked + 1))
done
printf 'Verified %d ECZOS source package version(s) against configured repositories.\n' "$checked"
