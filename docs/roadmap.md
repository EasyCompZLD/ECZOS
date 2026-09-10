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
- [ ] qualify the explicit `eczos` / `live` live identity and live-only no-lock policy on a new ISO
- [ ] qualify the ECZOS GRUB live menu and existing dark wallpaper on BIOS and UEFI
- [ ] replace Debian Installer internal product names, artwork and visible Debian-specific copy
- [ ] add the ECZOS Plasma startup splash from approved animation assets
- [ ] implement the ECZOS first-boot OOBE, including reviewed intro audio
- UEFI VM boot, install, upgrade and removal tests

## Phase 2 — ECZ Windows MVP

- [x] safe `.exe` and `.msi` handler (physical lifecycle tests passed)
- [x] isolated prefixes and versioned application records
- [x] 32-bit/64-bit system Wine runtime adapter
- [x] launcher/icon/menu integration (physical icon extraction test passed)
- [x] install logs, repair and recoverable removal (physical test passed)
- [x] constrained default file mappings without a Linux-root `Z:` drive

## Phase 3 — ECZ Gaming

- [x] Vulkan and 32-bit graphics diagnostics
- [x] Steam bootstrap and controller integration (positive launch test pending)
- [x] reviewed UMU adapter for non-Steam games (positive GPU test pending)
- per-game DXVK/VKD3D and runtime profiles
- [x] explicit Gaming Mode through GameMode adapter

## Phase 4 — broader product experience

- [x] migration assistant MVP for personal folders
- [x] unified native/Flatpak application discovery foundation
- [x] hardware and system diagnostics foundation
- [x] backup application and recovery entry points
- [x] phone integration and privacy-conscious support-report foundation
- [x] FreeOffice host inclusion and physical install test
- [ ] FreeOffice release artifact pinning and ISO integration
- [ ] optional cloud and enrolled remote-support services

## Phase 5 — distribution

- signed ECZOS package repository
- release channels and upgrade policy
- selected installer implementation
- reproducible production images and release qualification
