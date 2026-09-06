# ADR 0002: Build only from declared source

Status: accepted

## Decision

Release builds may use only version-controlled configuration, ECZOS source
packages and dependencies obtained from declared repositories. They must not
copy `/etc`, `/usr/share` or user configuration from the build host.

## Consequences

The old overlay and builder remain historical evidence. Every ECZOS-owned file
must have a package or an explicitly documented image-build owner. Build state
is disposable and a clean build is the reference build.
