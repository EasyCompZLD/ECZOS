# eczos-plymouth-theme lifecycle result — 2026-09-06

Host: Dell OptiPlex 780, Debian 13.6 amd64, legacy BIOS.

Result: automated lifecycle passed.

Verified operations:

- binary package build with `dpkg-buildpackage`;
- installation through APT;
- package status `install ok installed`;
- presence of the theme descriptor, script and ECZOS logo;
- availability of Plymouth's `script` plugin;
- discovery of `eczos` by `plymouth-set-default-theme`;
- temporary selection of the ECZOS theme;
- restoration of the previously selected theme;
- package purge and removal of the theme payload;
- clean dpkg/APT state after removal.

The lifecycle test intentionally did not rebuild the initramfs or change GRUB.
Those boot-affecting operations are isolated in the preview installer and have
a matching rollback script.
