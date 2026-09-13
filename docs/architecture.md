# ECZOS architecture

## Baseline

- Debian 13 (Trixie), amd64 first
- KDE Plasma 6
- SDDM
- standard APT, dpkg and systemd infrastructure
- Wayland as the preferred desktop session, with X11 compatibility where needed

Debian remains visible to software through the compatibility mechanisms it
expects. ECZOS branding and product metadata must not falsify package origins or
break distribution detection.

## Product pillars

1. **ECZ Platform** — packages, updates, profiles, diagnostics and recovery.
2. **ECZOS UX** — Plasma defaults, OOBE, layouts and branding.
3. **ECZ Windows** — safe Windows application installation and management.
4. **ECZ Gaming** — game profiles, Proton/UMU, DXVK/VKD3D and GPU diagnostics.
5. **ECZ Services** — optional backup, device, cloud and support integrations.
6. **ECZ Distribution** — signed repository, installer, images and releases.

## Ownership boundaries

ECZOS packages may install their own files under these namespaces:

```text
/etc/eczos/
/usr/lib/eczos/
/usr/share/eczos/
/var/lib/eczos/
/var/log/eczos/
```

Replacing a Debian-owned file requires an explicit design decision, package
relationship, upgrade test and rollback test. Copying complete `/usr/share`
trees from a development workstation is prohibited.

System defaults and per-user state are separate. A first-run operation may seed
defaults once; normal logins must not continuously overwrite user choices.

ECZOS Settings presents KDE configuration modules rather than copying their
implementation. KDE documents KCMs as reusable modules that may be opened by
`systemsettings` or `kcmshell6`; ECZOS discovers the installed list at runtime
and launches the same modules through `kcmshell6`. This preserves driver,
hardware, authorization, save/reset and future package functionality while the
ECZOS shell supplies clearer navigation. The original System Settings launcher
must remain available until a physical coverage test confirms every reported
module is reachable from ECZOS Settings. Real screenshots provide guided entry
points for appearance, displays and networking; the complete runtime-discovered
list remains below them so visual simplification never removes functionality.

## Package layers

The intended dependency direction is:

```text
eczos-release / eczos-branding / eczos-defaults
                     ↓
          eczos-desktop metapackage
                     ↓
      optional product and feature packages
```

ECZ Windows ships in the desktop product set because it is a core ECZOS feature,
but remains removable and must never become a boot dependency. Gaming and remote
support remain optional layers.
