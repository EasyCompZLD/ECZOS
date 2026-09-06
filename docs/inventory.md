# Initial workspace inventory

Inventory date: 2026-09-06.

The starting workspace was a normal directory on a network share, not a Git
repository. No target Debian machine was connected during this inventory.

## Historical material

- `Build/`: three bootable ISO images, approximately 9.2 GB combined.
- `easycomp-desktop/overlay/`: approximately 1,536 files copied from a build
  machine, including 981 Plasma, 382 Plymouth and 154 SDDM files.
- `easycomp-desktop/build-easycomp.sh`: experimental live-build script.
- `easycomp-desktop/debs/`: third-party OnlyOffice and customized RustDesk
  binary packages.
- `Assets/`: six canonical-looking branding images and experimental theme
  scripts.

Two inspectable ISO manifests identify Debian Trixie, Plasma 6 and SDDM 0.21.
One includes OnlyOffice even though the current build script does not add it,
which demonstrates dependence on unrecorded build state.

## Unsafe or non-reproducible findings

- The legacy builder uses a hard-coded `/build/easycomp-desktop` path.
- It only runs `lb config` when an old `config/` directory is absent.
- It copies complete host Plasma, SDDM and Plymouth directories.
- The captured overlay includes `/etc/fstab` and `/etc/machine-id`.
- Generated ISO images and third-party binaries were mixed with source.
- The customized remote-support package embeds a reusable access credential and
  automatically enables a root system service.
- The SDDM copy still identifies itself as KDE Breeze and needs correct license
  attribution before it can become an ECZOS package.

Historical files are retained locally as evidence. They are not approved inputs
for a release image.
