# ADR 0007 — ECZOS display identity with Debian compatibility ID

## Status

Accepted for development on 2026-09-06.

## Decision

`eczos-release` presents ECZOS through the human-facing `NAME`, `PRETTY_NAME`,
`VARIANT`, `LOGO` and support URL fields in `/etc/os-release`. It preserves
`ID=debian`, the Debian version ID and codename so scripts and applications can
still identify the actual compatible base.

The package uses `dpkg-divert` to preserve Debian's `/etc/os-release` symlink and
restores it on package removal. `/usr/lib/os-release` remains untouched. GRUB's
generated distributor label is set separately through an ECZOS-owned drop-in.

## Consequences

- Plasma and systemd display ECZOS as the operating-system product;
- Debian detection based on `ID` and codename keeps working;
- package removal has a defined restoration path;
- base upgrades and ECZOS release upgrades require explicit lifecycle testing.
