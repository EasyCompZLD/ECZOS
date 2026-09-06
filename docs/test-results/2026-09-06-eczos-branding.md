# eczos-branding lifecycle result — 2026-09-06

Host: Dell OptiPlex 780, Debian 13.6 amd64, legacy BIOS.

Result: passed.

Verified operations:

- binary package build with `dpkg-buildpackage`;
- installation through APT;
- package status `install ok installed`;
- presence of all six packaged branding assets;
- clean `dpkg --audit`;
- successful `apt-get check`;
- package purge;
- removal of the complete branding payload;
- clean dpkg/APT state after removal.

The resulting development package was approximately 3.4 MB installed from a
3.4 MB `.deb`, with an installed size of approximately 8.6 MB.

Two non-fatal environment warnings were observed: the combined lifecycle script
ran the build as root, and APT could not initially access the package as `_apt`
below the root-owned source path. The script now stages the `.deb` as a readable
temporary file before installation, eliminating the latter warning on future
runs. A dedicated unprivileged package-build user remains a later build-host
improvement.
