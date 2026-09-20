#!/usr/bin/env bash
set -Eeuo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
[[ $(id -u) -eq 0 ]] || { printf 'Run as root on ECZ-GamePC.\n' >&2; exit 2; }
source /etc/os-release
[[ ${ID:-} == debian && ${VERSION_CODENAME:-} == trixie ]] || {
    printf 'Debian 13 (trixie) is required.\n' >&2; exit 2;
}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RELEASE_DIR=${ECZOS_RELEASE_DIR:-/srv/eczos-releases/0.1.0}
LOG_DIR="$RELEASE_DIR/logs"
RUN_ID=$(date -u +%Y%m%d-%H%M%S)
RESUME=false
case ${1:-} in
    --resume) RESUME=true ;;
    '') ;;
    *) printf 'Usage: %s [--resume]\n' "$0" >&2; exit 2 ;;
esac
install -d -m 2775 "$LOG_DIR"
exec > >(tee "$LOG_DIR/finalize-$RUN_ID.log") 2>&1

printf 'ECZOS 0.1.0 release finalization started at %s UTC\n' "$RUN_ID"
"$ROOT_DIR/scripts/verify-source.sh"
"$ROOT_DIR/scripts/verify-release-0.1.0.sh"

printf '\n[1/3] Building and checksumming the final package bundle\n'
if $RESUME && [[ -s "$RELEASE_DIR/packages/SHA256SUMS" ]] &&
   [[ $(find "$RELEASE_DIR/packages" -maxdepth 1 -type f -name 'eczos-*.deb' | wc -l) -eq 15 ]] &&
   (cd "$RELEASE_DIR/packages" && sha256sum --check --status SHA256SUMS); then
    printf 'Existing verified package bundle retained (--resume).\n'
else
    "$ROOT_DIR/scripts/build-release-packages-vm.sh"
fi

printf '\n[2/3] Building and inspecting the final hybrid ISO\n'
if $RESUME && [[ -s "$RELEASE_DIR/images/ECZOS-0.1.0-amd64.iso" ]] &&
   (cd "$RELEASE_DIR/images" && sha256sum --check --status ECZOS-0.1.0-amd64.iso.sha256); then
    printf 'Existing verified release ISO retained (--resume).\n'
else
    "$ROOT_DIR/scripts/build-release-image-vm.sh"
fi

printf '\n[3/3] Signing and publishing the stable APT repository\n'
REPOSITORY_DIR=${ECZOS_REPOSITORY_DIR:-/srv/eczos-apt-repository}
REPOSITORY_USER=$(stat -c '%U' "$REPOSITORY_DIR")
if [[ $REPOSITORY_USER != root ]]; then
    printf 'Publishing as repository owner %s.\n' "$REPOSITORY_USER"
    runuser -u "$REPOSITORY_USER" -- \
        bash "$ROOT_DIR/scripts/publish-release-0.1.0-vm.sh"
else
    "$ROOT_DIR/scripts/publish-release-0.1.0-vm.sh"
fi

printf '\nECZOS 0.1.0 release finalization completed successfully.\n'
printf 'Packages: %s/packages\n' "$RELEASE_DIR"
printf 'ISO:      %s/images/ECZOS-0.1.0-amd64.iso\n' "$RELEASE_DIR"
printf 'Checksum: %s/images/ECZOS-0.1.0-amd64.iso.sha256\n' "$RELEASE_DIR"
printf 'Log:      %s/finalize-%s.log\n' "$LOG_DIR" "$RUN_ID"
