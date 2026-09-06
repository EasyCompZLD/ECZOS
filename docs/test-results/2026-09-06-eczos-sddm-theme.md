# eczos-sddm-theme lifecycle result — 2026-09-06

Host: Dell OptiPlex 780, Debian 13.6 amd64, legacy BIOS.

Result: automated lifecycle passed.

Verified operations:

- binary builds of `eczos-branding` and `eczos-sddm-theme`;
- installation of both packages through APT;
- package status `install ok installed`;
- SDDM configuration selecting `Current=eczos`;
- presence and validity of the ECZOS theme files and Breeze links;
- branding and theme readability as the `sddm` system user;
- enabled and active SDDM service;
- clean `dpkg --audit` and successful `apt-get check`;
- purge of both packages;
- removal of all package-owned configuration, theme and branding paths.

APT emitted a non-fatal sandbox warning because its `_apt` user could not
traverse the temporary staging directory, which was created with mode `0700`.
The test now changes only that disposable directory to mode `0755`; staged
packages remain mode `0644` and the directory is removed on exit.

The automated test deliberately did not restart SDDM. A subsequent preview
installation and reboot confirmed that the ECZOS login screen renders and works
on the physical test host. The visual SDDM test therefore passed.
