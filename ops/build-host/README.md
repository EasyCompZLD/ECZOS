# ECZOS build host

This directory records configuration specifically owned by the dedicated ECZOS
development machine. It is not installed into ECZOS product images.

The current host is a Dell OptiPlex 780 running Debian 13.6 amd64, Plasma 6 and
legacy BIOS boot. It has two CPU cores, approximately 3 GiB RAM and a 1 TB
mechanical disk. It is appropriate for package, legacy-BIOS and basic desktop
testing, but not representative for Vulkan/DXVK gaming qualification.

SSH authentication on this lab machine is managed manually by its owner and is
not controlled by the ECZOS source repository. Credentials must never be stored
in this repository or copied into ECZOS images.
