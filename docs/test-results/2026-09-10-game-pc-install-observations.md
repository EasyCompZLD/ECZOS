# Game-PC installation observations — 2026-09-10

The first isolated hardware-qualification ISO was written successfully and
booted on the Vulkan-capable game PC. Installation was still in progress when
these observations were recorded, so this is not an installation pass result.

## Observed release gaps

- The live GRUB menu shows the familiar default Debian artwork instead of the
  intended ECZOS background.
- Debian Installer still presents Debian product names, copy and visual styling
  rather than EasyComp Zeeland Operating System / ECZOS identity.
- The live account is implicit Debian Live state: username `user`, password
  `live`. Locking during a running installation can therefore strand a tester
  who does not know these defaults.
- The next image must explicitly define the live identity and disable automatic
  screen locking for the live installation session. Installed-user lock policy
  must remain a separate setting.

## Planned experience work after Windows integration tests

- Replace the Plasma startup splash with an ECZOS animation derived from the
  approved source animation. Plasma splash packaging requirements must be
  checked before deciding whether the MP4 is converted to frames or used by a
  QML media component.
- Build a native ECZOS first-boot OOBE instead of relying on scattered first-run
  defaults.
- Review and integrate the OOBE intro audio/video assets under `Assets/Oobe/`.
  Playback must remain optional and respect mute/accessibility choices.

Assets currently present:

- `02_mesh_animation_preview.mp4`
- `04_composite_preview.mp4`
- `ECZ_OS_OOBE_ambient_loop.mp4`
- `ECZ_OS_OOBE_refined_fullres.mp4`
- `ECZ_OS_OOBE_sunrise_test.mp4`
