# ECZOS build host

This directory records configuration specifically owned by the dedicated ECZOS
development machine. It is not installed into ECZOS product images.

The current host is a Dell OptiPlex 780 running Debian 13.6 amd64, Plasma 6 and
legacy BIOS boot. It has two CPU cores, approximately 3 GiB RAM and a 1 TB
mechanical disk. It is appropriate for package, legacy-BIOS and basic desktop
testing, but not representative for Vulkan/DXVK gaming qualification.

`sshd/99-eczos-build-host.conf` disables root password login while retaining
key-based root access during initial provisioning. A named administrative user
with sudo and individual keys should replace direct root administration later.
