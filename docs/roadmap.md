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
- [x] FreeOffice host inclusion and physical install test
- [x] FreeOffice release artifact pinning and ISO integration
- [ ] optional cloud and enrolled remote-support services

## Phase 5 — distribution

- signed ECZOS package repository
- release channels and upgrade policy
- [x] selected installer implementation (Calamares with ECZOS-owned presentation)
- [ ] reproducible production images and release qualification
