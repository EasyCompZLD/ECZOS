# ADR 0009 — ECZOS-branded Calamares installer

## Status

Accepted for hardware qualification on 2026-09-10.

## Decision

ECZOS uses Debian Trixie's packaged Calamares engine and Debian integration
modules, with ECZOS-owned branding, launchers and policy configuration. The ISO
does not embed Debian Installer. The GRUB installation entry boots the regular
live filesystem with an `eczos-installer` flag; the live session then starts
Calamares automatically.

The installer configuration explicitly creates the installed user in the
`sudo` group, writes the bootloader identity as `ECZOS`, retains the repository
configuration owned by `eczos-release`, and removes Calamares plus live-only
packages from the installed target.

## Consequences

- installer pages and progress slides present one coherent ECZOS identity;
- try and install modes use the same tested hardware and graphics stack;
- the Debian-packaged installer engine continues to receive Debian security and
  maintenance updates;
- partitioning, encrypted installation, BIOS, UEFI and dual-boot paths require
  physical qualification before a public release.
