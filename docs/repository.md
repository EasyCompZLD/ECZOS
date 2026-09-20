# ECZOS package repository

The primary archive is published at `https://repo.easycomp.cloud/eczos/`. An
identical standby mirror may be published at
`https://repo.easycompcloud.net/eczos/`. Clients use only the primary endpoint
until mirror failover has been tested; this avoids inconsistent metadata while
the mirror is synchronizing.

The archive is managed with `reprepro` and has two Debian 13 suites:

- `trixie` contains qualified stable ECZOS updates;
- `trixie-testing` contains development and hardware-qualification updates.

## Trust boundary

Create the repository signing key as the unprivileged repository operator on a
controlled Debian host. Protect it with a passphrase and back it up encrypted.
Never store the secret key, passphrase or complete GnuPG home in this source
tree, network share, webroot or installation image. On the dedicated repository
host, the passphrase may be kept in the external mode-600 file
`/srv/eczos-repository-secrets/repository-signing-passphrase`; the import tool
uses it to prime that user's GPG agent without printing it. Only the exported
public key at `keys/eczos-archive-keyring.gpg` is public.

After installing `reprepro` and `gnupg`, initialize an external repository with
the full fingerprint of an available secret signing key:

```sh
./scripts/init-eczos-repository.sh /srv/eczos-apt-repository FINGERPRINT
```

Import only built and qualified ECZOS packages. Development packages go to the
testing suite first:

```sh
./scripts/import-eczos-repository-packages.sh \
    /srv/eczos-apt-repository trixie-testing packages/eczos-*.deb
```

Promote a separately retained, tested package set to `trixie`; do not rebuild a
different binary with the same version. Every published package version must be
unique and immutable.

## ECZOS 0.1.0 release publication

The release scripts use one checksummed package bundle for both the stable
repository and the ISO. This prevents package binaries from changing between
publication and image creation.

On `ECZ-GamePC`, build the complete bundle as root:

```sh
cd /srv/eczos
./scripts/build-release-packages-vm.sh
```

After that succeeds, publish its 15 ECZOS packages to stable as the `ecz`
development user. The existing password and signing-key files below
`/srv/eczos-repository-secrets` are detected automatically:

```sh
cd /srv/eczos
./scripts/publish-release-0.1.0-vm.sh
```

Both commands stop until the formal ECZOS 0.1.0 asset-rights gate is approved.

## Publication

The Virtualmin document root for the primary endpoint is
`/home/easycomp/domains/repo.easycomp.cloud/public_html/eczos`. Publication
copies package payloads before the signed `dists` metadata. It deliberately does
not delete historical pool files, preserving downloads and rollback during an
index transition.

```sh
./scripts/publish-eczos-repository.sh \
    /srv/eczos-apt-repository \
    USER@repo.easycomp.cloud:/home/easycomp/domains/repo.easycomp.cloud/public_html/eczos
```

For the current password-authenticated Virtualmin account, keep the password
outside the source tree in a mode-600 file and set `ECZOS_SSH_PASSWORD_FILE`
plus `ECZOS_SSH_OPTIONS` when publishing. The script then configures `sshpass`
for rsync automatically; the password is never committed or printed.

Add the mirror target as the final argument only after its SSH account and
document root have been verified.

The client source and `eczos-archive-keyring` package are enabled only after a
clean machine can retrieve and authenticate both suites over HTTPS. Existing
images must continue to update from Debian even when the ECZOS archive is
temporarily unavailable.
