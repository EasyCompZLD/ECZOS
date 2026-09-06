# Development image build is intentionally blocked

Do not build a new ECZOS ISO yet. The pipeline is retained and verified, but the
following product gates must be completed first:

- start-menu icon and lock-screen branding visual test;
- ECZOS product name visual audit across Plasma and GRUB;
- first safe ECZ Windows MVP workflow;
- review of remaining visible Debian and KDE product strings;
- image package upgrade and rollback tests.

Remove this file in a reviewed commit only after those gates pass.
