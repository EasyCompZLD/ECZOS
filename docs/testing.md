# Testing

ECZOS system and package tests run inside a disposable Debian 13 amd64 VM. The
macOS host and the network share are source-storage environments, not valid
substitutes for dpkg, APT, systemd, SDDM or boot testing.

## Source checks

```sh
make test
```

These checks are read-only and can run from the shared project directory.

## Prepare a clean VM

Install Debian 13 amd64 in a VM, snapshot it, copy or clone the repository into
the VM and review `scripts/bootstrap-dev-vm.sh`. Run it as root only after that
review:

```sh
sudo ./scripts/bootstrap-dev-vm.sh
```

The script refuses non-Debian and non-Trixie systems. It installs development
packages but does not change repositories, desktop configuration or boot files.

## Branding package lifecycle

From the disposable VM:

```sh
sudo ./scripts/test-branding-package-vm.sh
```

The test builds, installs, validates and purges `eczos-branding`, then verifies
that no branding payload remains and that dpkg/APT are healthy. Revert the VM
snapshot after testing.

## Required gates for image work

- source checks pass;
- `lintian` output is reviewed;
- package installation and purge pass;
- `dpkg --audit` is empty;
- `apt-get check` succeeds;
- VM boot and shutdown succeed;
- an ordinary Debian update does not remove ECZOS-owned files;
- removing an ECZOS cosmetic package does not damage the desktop or boot path.
