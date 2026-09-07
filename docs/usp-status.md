# ECZOS USP implementation status

Status date: 2026-09-06.

| USP | Current implementation | Remaining release gate |
| --- | --- | --- |
| Windows apps without Wine complexity | EXE/MSI handler, confirmation, isolated prefix, launcher, icon extraction and manager | Physical MSI batch and broader app matrix |
| Per-app isolation | Implemented and physically tested | Upgrade/rollback matrix |
| Wine/Proton selection | Wine adapter plus UMU gaming adapter | Automatic game classification and positive Vulkan-PC test |
| Built-in Gaming Mode | Vulkan doctor, GameMode/UMU adapter and Debian Steam bootstrap | Per-game profiles and positive DXVK/VKD3D test |
| Windows migration | Safe personal-folder dry-run/apply MVP | Browser import, app transition mapping and OOBE page |
| Windows-style drives | Root `Z:` removed; explicit D:–Y: mappings stored per app and managed graphically | Broader network-drive discovery |
| Repair and diagnostics | Windows repair plus system, gaming and support diagnostics | Graphical guided system repair actions |
| One app ecosystem | Plasma Discover with APT, firmware and Flathub plus ECZ Windows launchers | Unified trust labels across all sources |
| Familiar Linux desktop | Windows-style Plasma defaults, ECZOS boot/login/console branding and native desktop app set | Optional dock layout and full OOBE |
| Support-aware OS | Local privacy-conscious support report | Vendor-approved remote-support enrollment |

## Standard application set

The ECZOS Desktop profile now specifies Firefox ESR, Thunderbird, VLC, Okular,
Gwenview, Ark, Spectacle, Discover, Flatpak/Flathub, KDE Connect, Kup Backup,
firmware management, printers, scanning, disk tools and Microsoft-compatible
metric fonts. Debian's Steam bootstrap and controller rules are included.
LibreOffice is explicitly excluded.

SoftMaker FreeOffice 2024 is the selected office suite. The next host batch
installs it from SoftMaker's signed APT repository. Before public ISO release,
the received permission scope and a pinned release artifact must be recorded.
