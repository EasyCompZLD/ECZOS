# Game-PC installation observations — 2026-09-10

The first isolated hardware-qualification ISO was written successfully, booted
and installed on the Vulkan-capable game PC. The installed host is named
`ECZ-GamePC` and now serves as the faster physical development and qualification
system. Windows integration tests were reported successful after installation.

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
- Source now defines the live account as `eczos` with the standard live password
  `live`, creates a live-account-only Plasma no-lock configuration, brands the
  live GRUB menu with the existing ECZOS dark wallpaper and replaces the
  desktop installer launcher's Debian-facing name and icon. A new ISO must still
  qualify these changes; the installer engine's internal screens remain a
  separate branding task.
- The installed image retained only the SoftMaker repository. Debian base,
  updates and security sources had to be restored manually. `eczos-release`
  dev5 now owns an `eczos-debian.sources` file for subsequent images.
- The installed user was not a member of the `sudo` group. This was repaired on
  the development host and remains an installer qualification check.

## Development-host compatibility exception

The requested Synergy 1.10.1 USB package predates Debian 13 and depends on
`libssl1.1`. The host uses Debian's archived Bullseye security build
`libssl1.1 1.1.1w-0+deb11u8` alongside the current OpenSSL runtime. No Bullseye
repository was permanently added. This exception is local to the development
host and must not enter the ECZOS desktop image.

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
