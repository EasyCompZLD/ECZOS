# ECZOS development image

This directory contains the versioned Debian Live configuration for the first
ECZOS development image. It is generated from Debian 13 (Trixie), the official
KDE live task and the ECZOS Debian packages in this repository. Nothing is
copied from the historical workstation overlay.

The prototype uses Debian Installer in live mode plus its desktop launcher.
Calamares remains a separate future decision.

The build pipeline is prepared but intentionally blocked by `BUILD_BLOCKED.md`
until the desktop branding and first ECZ Windows MVP gates pass. After that file
is removed in a reviewed commit, the entry point will be:

```sh
sudo ./scripts/build-image-vm.sh
```

The script will build every ECZOS package, stage the resulting `.deb` files in
`config/packages.chroot`, configures live-build, produces the ISO and writes a
SHA-256 checksum below `image/.build/artifacts/`.

Generated packages, caches, logs and images are intentionally ignored by Git.
The development build uses the current Trixie repositories; bit-for-bit release
reproducibility will require a pinned Debian snapshot and a signed ECZOS APT
repository.
