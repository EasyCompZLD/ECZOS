#!/usr/bin/env bash
set -Eeuo pipefail

REPOSITORY_DIR=${1:-}
SUITE=${2:-}
shift $(( $# >= 2 ? 2 : $# ))

if [[ -z "$REPOSITORY_DIR" || -z "$SUITE" || $# -eq 0 ]]; then
    printf 'Usage: %s REPOSITORY_DIR trixie|trixie-testing PACKAGE.deb [...]\n' "$0" >&2
    exit 2
fi
case "$SUITE" in
    trixie|trixie-testing) ;;
    *) printf 'Unknown ECZOS suite: %s\n' "$SUITE" >&2; exit 2 ;;
esac
command -v reprepro >/dev/null 2>&1 || {
    printf 'reprepro is required.\n' >&2
    exit 1
}

for package_file in "$@"; do
    [[ -f "$package_file" ]] || {
        printf 'Package does not exist: %s\n' "$package_file" >&2
        exit 1
    }
    package_name=$(dpkg-deb -f "$package_file" Package)
    package_arch=$(dpkg-deb -f "$package_file" Architecture)
    [[ "$package_name" == eczos-* ]] || {
        printf 'Refusing non-ECZOS package: %s\n' "$package_name" >&2
        exit 1
    }
    case "$package_arch" in
        all|amd64) ;;
        *) printf 'Unsupported package architecture: %s\n' "$package_arch" >&2; exit 1 ;;
    esac
done

for package_file in "$@"; do
    reprepro --basedir "$REPOSITORY_DIR" includedeb "$SUITE" "$package_file"
done
reprepro --basedir "$REPOSITORY_DIR" check "$SUITE"
reprepro --basedir "$REPOSITORY_DIR" export "$SUITE"

printf 'Imported %d signed ECZOS package(s) into %s.\n' "$#" "$SUITE"
