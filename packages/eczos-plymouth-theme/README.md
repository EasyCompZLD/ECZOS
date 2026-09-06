# eczos-plymouth-theme

This Debian package installs the existing animated ECZOS Plymouth boot theme.
It uses Plymouth's `two-step` plugin with the approved runtime images recovered
from the working ECZOS prototype. Editor files, previews and unused source
frames are deliberately excluded from the binary package.

Installing the package makes the theme available but does not silently change
the machine's selected theme, initramfs or kernel command line. Image profiles
and the dedicated preview script perform that policy step explicitly.
