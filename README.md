# ECZOS

ECZOS is an EasyComp Zeeland operating-system product layer built on Debian.
The current development baseline is Debian 13 (Trixie), KDE Plasma 6 and SDDM.

The project is not a fork of Debian and must not replace Debian-owned files for
branding alone. ECZOS-specific behaviour is delivered through versioned Debian
packages, declarative profiles and a reproducible image configuration.

## Current status

This repository is the clean-source replacement for an earlier collection of
machine snapshots and experimental ISO builds. The historical material remains
on the share for reference, but is intentionally excluded from Git.

The first components are `eczos-branding`, which installs EasyComp-owned assets
below `/usr/share/eczos/branding`, and `eczos-sddm-theme`, which selects an
ECZOS login theme while inheriting Debian's packaged Breeze implementation.
The animated Plymouth theme and one-time Plasma defaults extend that visible
prototype without replacing files owned by Debian packages.

## Layout

```text
docs/                       Architecture, decisions, security and roadmap
packages/eczos-branding/    First Debian source package
packages/eczos-sddm-theme/  ECZOS login theme and SDDM configuration
packages/eczos-plymouth-theme/ ECZOS boot-splash theme
packages/eczos-desktop-defaults/ One-time Plasma appearance defaults
packages/eczos-release/       Product identity without masking Debian
packages/eczos-windows-core/  Managed EXE/MSI compatibility MVP
packages/eczos-gaming-core/   Vulkan and UMU/Proton readiness gate
packages/eczos-platform-tools/ Control center, migration and diagnostics
packages/eczos-desktop-apps/  Supported native application metapackage
packages/eczos-desktop/       Complete desktop product-layer metapackage
scripts/                    Source-tree developer checks
tests/                      Automated source and package tests
image/                      Versioned Debian live-build configuration
```

The directories `Build/`, `Assets/` and `easycomp-desktop/` predate this source
layout. `Build/` and the old machine overlay are not source and are ignored.
Canonical assets are copied into their owning package.

## Development

Run the source checks on any Unix-like development machine:

```sh
./scripts/verify-source.sh
```

Run the package lifecycle tests on the dedicated Debian 13 test host:

```sh
sudo ./scripts/test-branding-package-vm.sh
sudo ./scripts/test-sddm-theme-package-vm.sh
sudo ./scripts/test-plymouth-theme-package-vm.sh
sudo ./scripts/test-desktop-defaults-package-vm.sh
```

The current combined product gate is run on that host with:

```sh
sudo ./scripts/install-next-product-batch-vm.sh
```

It installs FreeOffice from the signed SoftMaker repository and tests the ECZ
Windows MSI, extracted-icon, repair and removal lifecycle before producing a
visible-branding audit.

No production image should include the historical remote-support package. See
`docs/security.md`.

The complete image pipeline is present, but `image/BUILD_BLOCKED.md` prevents a
premature ISO build until the remaining desktop and ECZ Windows gates pass.
After that reviewed gate is removed, build on Debian 13 with:

```sh
sudo ./scripts/build-image-vm.sh
```

## GitHub release upload directory

The allowlisted files for the latest GitHub release are generated in
`Build/GitHub/UPLOAD-THIS-TO-GITHUB/`. Refresh the directory manually with:

```sh
make github-upload
```

This checkout also uses the tracked `.githooks/post-commit` hook to refresh the
directory after every commit. Only the release notes, checksum and upload
instructions are copied. ISO images, credentials, signing keys and build caches
are deliberately excluded.
