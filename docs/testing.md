# Testing

ECZOS package builds currently run on the dedicated Debian 13 amd64 OptiPlex
build host. The macOS host and network share are source-storage environments,
not valid substitutes for dpkg, APT, systemd, SDDM or boot testing.

Destructive system, installer and rollback tests still require a disposable VM
or a separately imaged test disk. Low-risk package lifecycle tests may run on
the build host when their payload and removal behaviour have been reviewed.

## Source checks

```sh
make test
```

These checks are read-only and can run from the shared project directory.

## Prepare the Debian build host

Copy or clone the repository to the dedicated Debian 13 host and review
`scripts/bootstrap-dev-vm.sh`. Run it as root only after that review:

```sh
sudo ./scripts/bootstrap-dev-vm.sh
```

The script refuses non-Debian and non-Trixie systems. It installs development
packages but does not change repositories, desktop configuration or boot files.
Despite its historical filename, it is also suitable for the physical build
host.

## Branding package lifecycle

For the static branding package, from the dedicated build host:

```sh
sudo ./scripts/test-branding-package-vm.sh
```

The test builds, installs, validates and purges `eczos-branding`, then verifies
that no branding payload remains and that dpkg/APT are healthy. Packages with
maintainer scripts or system configuration changes must not use this shortcut;
test those on a disposable target first.

## Login and boot theme lifecycles

The SDDM lifecycle test installs both login-theme packages, verifies the live
service configuration and then purges both packages:

```sh
sudo ./scripts/test-sddm-theme-package-vm.sh
```

The Plymouth lifecycle test builds, installs, temporarily selects, restores and
purges the boot theme without rebuilding the initramfs:

```sh
sudo ./scripts/test-plymouth-theme-package-vm.sh
```

Only after that lifecycle passes, use `install-plymouth-theme-preview.sh`. It
records the previous theme, enables the GRUB `splash` argument and rebuilds the
initramfs. `remove-plymouth-theme-preview.sh` performs the tested rollback.

During rapid prototype work, `stage-next-desktop-preview-vm.sh` builds and
installs the current Plymouth and desktop-default packages, runs both installed
package smoke tests, activates the Plymouth preview and leaves the batch ready
for one reboot. It does not purge the already working SDDM or branding packages.

`stage-platform-batch-vm.sh` builds and installs the corrected desktop defaults,
ECZOS release identity and the aggregate desktop metapackage in one run. Its
smoke tests also confirm that Debian remains the underlying compatibility ID.

## Development image

`build-image-vm.sh` is the single entry point for a full image build. It verifies
the source, creates all ECZOS packages in dependency order, stages them for
live-build, cleans previous generated state and builds a Debian 13 KDE hybrid
ISO. A successful build is not a release: the ISO must still pass BIOS and UEFI
boot, live-session, installer, installed-system and removal tests.

## Required gates for image work

- source checks pass;
- `lintian` output is reviewed;
- package installation and purge pass;
- `dpkg --audit` is empty;
- `apt-get check` succeeds;
- VM boot and shutdown succeed;
- an ordinary Debian update does not remove ECZOS-owned files;
- removing an ECZOS cosmetic package does not damage the desktop or boot path.
