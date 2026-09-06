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

The first component is `eczos-branding`, a deliberately low-risk package that
installs only EasyComp-owned branding assets below `/usr/share/eczos/branding`.
It does not change GRUB, Plymouth, SDDM, APT, `/etc/os-release` or user settings.

## Layout

```text
docs/                       Architecture, decisions, security and roadmap
packages/eczos-branding/    First Debian source package
scripts/                    Source-tree developer checks
tests/                      Automated source and package tests
image/                      Future reproducible live-build configuration
```

The directories `Build/`, `Assets/` and `easycomp-desktop/` predate this source
layout. `Build/` and the old machine overlay are not source and are ignored.
Canonical assets are copied into their owning package.

## Development

Run the source checks on any Unix-like development machine:

```sh
./scripts/verify-source.sh
```

Build the package inside a clean Debian 13 VM or container:

```sh
cd packages/eczos-branding
dpkg-buildpackage -us -uc -b
```

No production image should include the historical remote-support package. See
`docs/security.md`.
