# Development image build is intentionally blocked

Do not build a new ECZOS ISO yet. The pipeline is retained and verified, but the
following product gates must be completed first:

- run the complete product-experience installation and removal checks;
- complete the MSI, Windows icon and guided-repair tests;
- perform a positive Proton/DXVK test on a hardware Vulkan GPU;
- resolve the FreeOffice redistribution-permission gate;
- review of remaining visible Debian and KDE product strings;
- image package upgrade and rollback tests.

Remove this file in a reviewed commit only after those gates pass.
