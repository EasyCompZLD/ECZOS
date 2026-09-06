# ADR 0004 — Plymouth theme selection is profile policy

## Status

Accepted on 2026-09-06.

## Decision

`eczos-plymouth-theme` installs only the self-contained ECZOS theme. It does not
edit `/etc/plymouth/plymouthd.conf`, rebuild initramfs images or change the GRUB
kernel command line from Debian package maintainer scripts.

The future ECZOS image profile will select the theme and enable the `splash`
kernel argument. Development uses dedicated preview install/removal scripts
which record and restore the previously selected theme.

The theme uses Plymouth's standard `script` plugin and one existing ECZOS logo.
It does not import the historical machine snapshot or its 52-image theme copy.

## Consequences

- installing or removing the theme package alone has no boot-policy side effects;
- rollback does not depend on a theme file that has already been removed;
- initramfs regeneration happens only when selection actually changes;
- image integration must explicitly select the ECZOS theme and enable `splash`.
