# Classic-game laptop qualification — 2026-09-13

The current hardware-qualification image booted and installed on an older Acer
Aspire 7540 laptop. The live identity, Calamares path, first-boot OOBE and the
password-authenticated `sudo` membership of the created `ecz` user were
physically verified. Debian base, updates and security sources plus the
SoftMaker source survived installation.

The first Plasma login still showed the Breeze splash because Plasma prepends a
new user's generated `~/.config/kdedefaults/ksplashrc` to the system search
path. `eczos-desktop-defaults` dev7 seeds `/etc/skel/.config/ksplashrc`; this
correction remains pending qualification in the next clean image.

The next image also carries the same `ksplashrc` directly in its `/etc/skel`
overlay, independently of package installation order. Its live GRUB input now
contains an explicit ECZOS `splash.png` identical to the approved dark
wallpaper, preventing live-build from falling back to Debian artwork.

Tactical Ops was installed and played from its original optical medium. This
test exposed and then verified fixes for transient disc read failures, visible
copy progress, resumable media copies, unreliable autorun exit codes, product
executable selection, icon extraction, Games-menu categorization and desktop
launcher creation. The Radeon HD 4570 has no hardware Vulkan support and is an
appropriate classic-Wine target, not a Proton/DXVK qualification target.

The first-session defaults service also exposed a Plasma D-Bus startup race.
Dev8 bounds slow wallpaper and panel calls, records non-fatal warnings and uses
direct launcher artwork. The image now removes live-build's duplicate legacy
APT source list because `eczos-release` owns the equivalent deb822 sources.

## Boot presentation follow-up

The ECZOS Plymouth theme was physically requalified on the GamePC after its
initramfs was rebuilt. Normal boot now shows only the existing ECZOS animation:
there is no Debian fallback logo, duplicate secondary logo or normal-boot text.
The package keeps Plymouth's global fallback transparent while installed and
restores Debian's original fallback on package removal.
