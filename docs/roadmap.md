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
- [ ] first ECZOS ISO build and boot test (blocked until desktop and ECZ Windows MVP gates pass)
- UEFI VM boot, install, upgrade and removal tests

## Phase 2 — ECZ Windows MVP

- [ ] safe `.exe` and `.msi` handler (`.exe` physical test passed; MSI pending)
- [x] isolated prefixes and versioned application records
- [x] 32-bit/64-bit system Wine runtime adapter
- [ ] launcher/icon/menu integration (launcher passed; real icon extraction pending)
- [ ] install logs, repair and recoverable removal (implemented; test pending)
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
- [ ] FreeOffice inclusion (host integration prepared; physical and image tests pending)
- [ ] optional cloud and enrolled remote-support services

## Phase 5 — distribution

- signed ECZOS package repository
- release channels and upgrade policy
- selected installer implementation
- reproducible production images and release qualification
