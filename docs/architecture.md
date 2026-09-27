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

`eczos-platform-core` owns the shared capability-result schema and the
configuration migration registry. Feature packages keep their own detection
and repair implementations, but publish stable status and reason codes through
that contract. Released migrations are immutable, idempotent package-owned
executables and are recorded with their checksum after successful completion.

Network optical drives follow the same native-settings boundary. The Settings
page is unprivileged, a read-only JSON backend discovers state, and a narrowly
scoped Polkit helper controls Linux LIO/pSCSI, Open-iSCSI and Avahi. See
`docs/network-optical-drives.md` for the data flow and exclusivity model.

General network locations stay user-scoped and use KDE KIO for SMB, NFS,
WebDAV and SFTP. Authentication is delegated to KDE Wallet; ECZOS never stores
passwords in its registry or accepts them embedded in URLs. KIO-Fuse provides
local paths when non-KIO applications need them. Existing native mounts are
reported read-only and are not silently adopted or rewritten by ECZOS.

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

ECZOS Settings embeds KDE configuration modules rather than copying their
implementation. A native host uses `KCModuleLoader` to place both Qt Quick and
legacy QtWidgets KCMs inside the ECZOS window. This preserves driver, hardware,
authorization, save/reset and future package functionality without spawning a
standalone `kcmshell6` window. It discovers normal System Settings and Info
Center namespaces at runtime, applies KDE authorization and platform filters,
and exposes every resulting module in the ECZOS sidebar. The original System
Settings launcher must remain available until a physical coverage test confirms
every reported module is usable from ECZOS Settings. Real screenshots provide
guided context for appearance, displays and networking without replacing the
complete module list.

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
