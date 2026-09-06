# Roadmap

## Phase 0 — source foundation

- [x] Git history and repository policy
- [x] Debian 13 architecture decision
- [x] inventory and threat model
- [x] first low-risk Debian package
- [x] Debian 13 build/test host
- [x] `eczos-branding` build, install and purge lifecycle

## Phase 1 — reproducible desktop prototype

- ECZOS branding, SDDM and Plymouth packages
- Plasma defaults and Windows-style layout
- first-run state mechanism
- reproducible live-build configuration
- UEFI VM boot, install, upgrade and removal tests

## Phase 2 — ECZ Windows MVP

- safe `.exe` and `.msi` handler
- isolated prefixes and versioned application records
- Wine runtime adapter
- launcher/icon/menu integration
- logs, repair and removal
- constrained file and drive access

## Phase 3 — ECZ Gaming

- Vulkan and 32-bit graphics diagnostics
- Steam integration
- reviewed UMU adapter for non-Steam games
- per-game DXVK/VKD3D and runtime profiles
- explicit Gaming Mode

## Phase 4 — broader product experience

- migration assistant
- unified application discovery
- hardware guidance
- backup and recovery
- optional device, cloud and support services

## Phase 5 — distribution

- signed ECZOS package repository
- release channels and upgrade policy
- selected installer implementation
- reproducible production images and release qualification
