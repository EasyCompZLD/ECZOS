# Roadmap

## Phase 0 — source foundation

- [x] Git history and repository policy
- [x] Debian 13 architecture decision
- [x] inventory and threat model
- [x] first low-risk Debian package
- [x] Debian 13 build/test host
- [x] `eczos-branding` build, install and purge lifecycle

## Phase 1 — reproducible desktop prototype

- [x] ECZOS branding package lifecycle
- [x] ECZOS SDDM package lifecycle
- [x] visual SDDM login-screen test
- [x] ECZOS Plymouth package lifecycle
- [x] visual Plymouth boot-splash test
- [x] Plasma defaults and Windows-style layout
- [x] first-run state mechanism
- [x] versioned Debian 13 KDE live-build configuration
- [x] first isolated ECZOS hardware-qualification ISO build
- [x] hardware-qualification ISO boot and installation on the Vulkan-capable game PC
- [x] qualify the explicit `eczos` / `live` live identity and live-only no-lock policy on a new ISO
- [ ] qualify the ECZOS GRUB live menu and existing dark wallpaper on BIOS and UEFI
- [x] qualify the ECZOS-branded Calamares installation path and USP slideshow
- [x] qualify the ECZOS Plasma startup splash from the approved animation asset
- [x] qualify the ECZOS first-boot OOBE with default-on, user-mutable intro audio
- [x] qualify Calamares-created users as password-authenticated sudo members
- UEFI VM boot, install, upgrade and removal tests

## Phase 2 — ECZ Windows MVP

- [x] safe `.exe` and `.msi` handler (physical lifecycle tests passed)
- [x] isolated prefixes and versioned application records
- [x] 32-bit/64-bit system Wine runtime adapter
- [x] launcher/icon/menu integration (physical icon extraction test passed)
- [x] install logs, repair and recoverable removal (physical test passed)
- [x] constrained default file mappings without a Linux-root `Z:` drive
- [x] physical classic-game installation from optical media with progress,
      recovery, executable discovery and categorized launchers

## Phase 3 — ECZ Gaming

- [x] Vulkan and 32-bit graphics diagnostics
- [x] Steam bootstrap and controller integration (physically launched on GamePC)
- [x] reviewed UMU adapter for non-Steam games
- optional expanding per-game DXVK/VKD3D and runtime compatibility matrix
- [x] explicit Gaming Mode through GameMode adapter
- [x] guided repair for missing 32-bit Vulkan, GameMode and UMU/Proton support

Steam operation on the GamePC qualifies the current gaming integration. Separate
Vulkan, DXVK, VKD3D and UMU game tests may expand the compatibility matrix later,
but are not a prototype release blocker.

## Phase 4 — broader product experience

- [x] migration assistant MVP for personal folders
- [x] unified native/Flatpak application discovery foundation
- [x] hardware and system diagnostics foundation
- [x] backup application and recovery entry points
- [x] phone integration and privacy-conscious support-report foundation
- [x] unified ECZOS Qt interface for settings, Windows apps, gaming,
      migration, diagnostics, recovery media and support
- [x] terminal-free recovery-media workflow with progress and ETA
- [x] real product screenshots in the installer and first-boot OOBE
- [x] qualify all 87 discovered KDE configuration modules inside ECZOS
      Settings and redirect legacy System Settings/KCM launchers to the same
      ECZOS window
- [x] replace Debian's forced About This System logo and version override with
      ECZOS release identity
- [x] FreeOffice host inclusion and physical install test
- [x] FreeOffice release artifact pinning and ISO integration
- [x] modular package architecture: product identity remains required while
      applications, Windows, Gaming, recovery and remote-device features are
      independently removable
- [x] user-scoped SMB, NFS, WebDAV and SFTP locations through KDE KIO/KWallet,
      including LAN discovery and visibility of existing native mounts
- [x] persistent normal/Advanced mode split in ECZOS Settings; technical logs,
      runner controls, raw hardware data and boot internals remain available
      without crowding the default consumer interface
- [x] central journal-based ECZOS activity reader, full-report privacy filter
      and reviewed email/GitHub support hand-off
- [ ] optional cloud and enrolled remote-support services
- [ ] experimental ECZ Mac compatibility based on Darling, initially limited
      to separately installed CLI and simple GUI applications; this is not a
      prototype-release blocker

## Next hardware-qualification image

- [ ] verify the off-canvas Plymouth watermark correction on a clean boot
- [ ] verify that every Start-menu settings entry opens ECZOS Settings
- [ ] verify Users, Printers, Backups and About This System inside the ECZOS
      window on a freshly installed account
- [ ] verify the ECZOS logo and version on About This System
- [ ] recheck first-login ECZOS splash, OOBE, installer slideshow and audio
- [ ] boot and install the same image in both BIOS and UEFI mode

## Phase 5 — distribution

- [ ] signed ECZOS package repository
  - [x] primary and mirror endpoints plus stable/testing archive layout
  - [x] local initialization, package import and safe publication tooling
  - [ ] protected signing key and first signed repository export
  - [ ] public HTTPS authentication and clean-client update test
  - [ ] `eczos-archive-keyring` and ECZOS client source integration
- release channels and upgrade policy
- [x] versioned configuration-migration foundation with full preflight,
      checksum drift detection, failure state and safe retry behaviour
- [ ] qualify configuration migrations across a real multi-version upgrade
      and rollback matrix
- [x] selected installer implementation (Calamares with ECZOS-owned presentation)
- [ ] reproducible production images and release qualification
