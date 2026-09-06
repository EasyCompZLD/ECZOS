# eczos-plymouth-theme

This Debian package installs the ECZOS Plymouth boot theme. It uses Plymouth's
standard `script` plugin and an ECZOS-owned copy of the existing power logo.

Installing the package makes the theme available but does not silently change
the machine's selected theme, initramfs or kernel command line. Image profiles
and the dedicated preview script perform that policy step explicitly.
