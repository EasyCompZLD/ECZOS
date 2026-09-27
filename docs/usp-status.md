# ECZOS USP implementation status

Status date: 2026-09-14.

| USP | Current implementation | Remaining release gate |
| --- | --- | --- |
| Windows apps without Wine complexity | EXE/MSI handler, confirmation, isolated prefix, launcher, icon extraction, repair and recoverable removal | Broader real-app matrix |
| Per-app isolation | Implemented and physically tested | Upgrade/rollback matrix |
| Wine/Proton selection | Wine adapter plus UMU gaming adapter | Optional broader per-game compatibility matrix |
| Built-in Gaming Mode | Vulkan doctor, GameMode/UMU adapter and physically launched Debian Steam bootstrap | Optional per-game profiles and DXVK/VKD3D qualification |
| Windows migration | Safe personal-folder dry-run/apply MVP | Browser import, app transition mapping and OOBE page |
| Windows-style drives | Root `Z:` removed; explicit D:–Y: mappings stored per app and managed graphically | Broader network-drive discovery |
| Repair and diagnostics | Unified ECZOS interface with Windows repair plus system, gaming and support diagnostics | Guided automatic system repair actions |
| One app ecosystem | Plasma Discover with APT, firmware and Flathub plus ECZ Windows launchers | Unified trust labels across all sources |
| Familiar Linux desktop | Windows-style Plasma defaults, ECZOS boot/login/console branding, unified native tools and a screenshot-rich OOBE | Optional dock layout |
| Support-aware OS | Local privacy-filtered report, central ECZOS activity view and reviewed email/GitHub hand-off | Vendor-approved remote-support enrollment |
| Unified settings | ECZOS tools and all 87 discovered KDE modules share one native window; legacy settings launch commands are redirected | Fresh-install BIOS/UEFI qualification |
| Network locations | SMB, NFS, WebDAV and SFTP locations are managed in ECZOS Settings through KIO, KIO-Fuse and KDE Wallet; native mounts remain visible without being overwritten | Broader physical server and credential-recovery matrix |
| Predictable upgrades | Package-owned configuration migrations are preflighted, checksummed, logged and safely retryable; optional feature packages remain removable | Multi-version upgrade and rollback qualification |
| Accessible and powerful | Consumer-first settings with a persistent Advanced mode for technical logs and specialist controls | Broader usability qualification with new users |
| Mac application experiment | Darling feasibility recorded for a future optional ECZ Mac layer | Complex GUI applications are not yet dependable; not a release blocker |

## Standard application set

The ECZOS Desktop profile now specifies Firefox ESR, Thunderbird, VLC, Okular,
Gwenview, Ark, Spectacle, Discover, Flatpak/Flathub, KDE Connect, Kup Backup,
firmware management, printers, scanning, disk tools and Microsoft-compatible
metric fonts. Debian's Steam bootstrap and controller rules are included.
LibreOffice is explicitly excluded.

SoftMaker FreeOffice 2024 version 3702 is installed and physically tested from
SoftMaker's signed APT repository. Before public ISO release, the received
permission scope and a pinned release artifact must be recorded.
