# ECZOS development image

This directory contains the versioned Debian Live configuration for the first
ECZOS development image. It is generated from Debian 13 (Trixie), the official
KDE live task and the ECZOS Debian packages in this repository. Nothing is
copied from the historical workstation overlay.

The hardware-qualification image uses Debian's Calamares engine with ECZOS-owned
branding, launchers and configuration. Both GRUB choices enter the same live
filesystem: `ECZOS proberen` opens the desktop, while `ECZOS installeren`
automatically starts Calamares. Debian Installer is not embedded. Calamares
creates the installed user in the `sudo` group and removes live-only installer
packages from the target.

The build pipeline is prepared but intentionally blocked by `BUILD_BLOCKED.md`
until the desktop branding and first ECZ Windows MVP gates pass. After that file
is removed in a reviewed commit, the entry point will be:

```sh
sudo ./scripts/build-image-vm.sh
```

Before the public-release gates pass, use only
`build-hardware-qualification-image-vm.sh` with its explicit environment flag
for a test ISO on a capable game PC. It embeds a checksum-pinned FreeOffice 2024
package and is not a public release.

The script will build every ECZOS package, stage the resulting `.deb` files in
`config/packages.chroot`, configures live-build, produces the ISO and writes a
SHA-256 checksum below `image/.build/artifacts/`.

Generated packages, caches, logs and images are intentionally ignored by Git.
The development build uses the current Trixie repositories; bit-for-bit release
reproducibility will require a pinned Debian snapshot and a signed ECZOS APT
repository.
