#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'Run as root on the ECZOS Debian 13 development host.\n' >&2
    exit 2
fi

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != debian || ${VERSION_CODENAME:-} != trixie ]]; then
    printf 'Refusing to run: Debian 13 (trixie) is required.\n' >&2
    exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGES=(eczos-archive-keyring eczos-release eczos-branding eczos-platform-core eczos-platform-tools eczos-gaming-core eczos-desktop)

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    cmake \
    extra-cmake-modules \
    libkf6auth-dev \
    libkf6config-dev \
    libkf6coreaddons-dev \
    libkf6kcmutils-dev \
    qt6-base-dev \
    qt6-declarative-dev
"$ROOT_DIR/scripts/normalize-image-source-permissions-vm.sh"
"$ROOT_DIR/scripts/verify-source.sh"

for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    find "$package_dir/debian" -type f -exec chmod 0644 {} +
    chmod 0755 "$package_dir/debian/rules"
    for maintainer_script in preinst postinst prerm postrm config; do
        if [[ -f "$package_dir/debian/$maintainer_script" ]]; then
            chmod 0755 "$package_dir/debian/$maintainer_script"
        fi
    done
    for executable_dir in bin lib; do
        if [[ -d "$package_dir/$executable_dir" ]]; then
            find "$package_dir/$executable_dir" -type f -exec chmod 0755 {} +
        fi
    done
    for data_dir in applications assets branding config keyrings polkit product qml runtime-definitions xdg; do
        if [[ -d "$package_dir/$data_dir" ]]; then
            find "$package_dir/$data_dir" -type f -exec chmod 0644 {} +
        fi
    done
    (cd "$package_dir" && dpkg-buildpackage -us -uc -b)
done

debs=()
for package in "${PACKAGES[@]}"; do
    package_dir="$ROOT_DIR/packages/$package"
    version=$(dpkg-parsechangelog -l"$package_dir/debian/changelog" -S Version)
    package_arch=$(awk '/^Architecture:/ {print $2; exit}' "$package_dir/debian/control")
    [[ $package_arch == all ]] || package_arch=$(dpkg-architecture -qDEB_HOST_ARCH)
    debs+=("$ROOT_DIR/packages/${package}_${version}_${package_arch}.deb")
done
apt-get install -y "${debs[@]}"

"$ROOT_DIR/tests/smoke/archive-keyring-package.sh"
"$ROOT_DIR/tests/smoke/release-package.sh"
"$ROOT_DIR/tests/smoke/branding-package.sh"
"$ROOT_DIR/tests/smoke/platform-core-package.sh"
"$ROOT_DIR/tests/smoke/platform-tools-package.sh"
"$ROOT_DIR/tests/smoke/gaming-core-package.sh"
"$ROOT_DIR/tests/smoke/desktop-metapackage.sh"

module_json=$(QT_QPA_PLATFORM=offscreen /usr/bin/eczos-system-settings --list-json)
jq -e '
    (.modules | length >= 80) and
    ([.modules[].id] | contains([
        "kcm_users", "kcm_networkmanagement", "kcm_kscreen",
        "kcm_pulseaudio", "kcm_printer_manager", "kcm_updates",
        "kcm_powerdevilprofilesconfig", "kcm_lookandfeel", "kcm_firewall"
    ]))
' <<<"$module_json" >/dev/null

set +e
QT_QPA_PLATFORM=offscreen timeout 5 /usr/bin/eczos-ui system >/tmp/eczos-settings-offscreen.log 2>&1
ui_status=$?
set -e
if [[ $ui_status -ne 124 ]]; then
    cat /tmp/eczos-settings-offscreen.log >&2
    printf 'ECZOS Settings did not remain running during the offscreen UI test.\n' >&2
    exit 1
fi

printf '\nECZOS Settings and Gaming repair batch passed.\n'
printf 'Open ECZOS Instellingen > Systeeminstellingen and ECZ Gaming for the visual check.\n'
