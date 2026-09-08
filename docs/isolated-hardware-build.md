# Isolated hardware qualification builds

Use `ECZOS_HARDWARE_QUALIFICATION=1 bash scripts/build-hardware-qualification-image-vm.sh`
on the dedicated Debian 13 build host. Long builds are run by the operator.
`--prepare-only` checks the configuration and isolation without building packages.

Each attempt gets a unique `/srv/eczos-builds/run-*` directory, a full build log,
input checksums, tool versions, and a checksummed ISO in `artifacts/` after basic
artifact checks. Hardware boot and installation tests remain separate gates.
The source remains in `/srv/eczos`. Do not run multiple legacy/manual builds
alongside this procedure; the lock covers the isolated entry points only.

The former resume and cache-rebuild entry points now call the same isolated
builder. They do not resume stages. No existing build directory is deleted.
Only downloaded `.deb` files from the legacy package caches are reused; APT
fetches current indexes. Bootstrap filesystem caches, installer caches, generated
APT preferences, stage markers and binary output are not reused. Packages must
be configured again, but cached downloads can save network time.

## Why the previous retries failed

The September 8 log ends with an existing `binary/dists/testing/trixie` link.
The installed live-build installer code uses `ln -s` to create distribution links;
forcing it again with existing links is not idempotent. Earlier recovery attempts
also mixed installer/binary helper chroots with the live filesystem. The leftover
`lb_chroot_apt install-binary` preference pinned Debian packages to priority 99,
below installed packages (100), preventing required multiarch security upgrades.
Removing ECZOS's essential-package dependencies alone did not fix that state.

The stock `lb build noauto` stage order is correct in a fresh tree. The old
`auto/build` wrapper merely calls that command; it was not itself the cause.
Global `APT::Default-Release=trixie-security` was a workaround for stale pins and
is no longer injected. APT uses normal repository priorities in a fresh tree.

If a build fails, preserve its log and directory. Diagnose before retrying; never
apply `--force` or manually remove markers to guess a resume point. This procedure
isolates mutable state but does not pin the Debian repository to a snapshot, so
it is not yet a bit-for-bit reproducible release pipeline.
