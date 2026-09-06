# ADR 0006 — Debian Live Installer for the first development image

## Status

Accepted for the development prototype on 2026-09-06.

## Decision

The first ECZOS ISO enables Debian Installer in live mode and includes
`debian-installer-launcher` for desktop access. This uses Debian's supported
copy-the-live-filesystem installation path and avoids importing installer state
from the historical image.

Calamares is not rejected, but its branding, modules, partition policy, OEM
workflow and upgrade behaviour need a separate review before ECZOS adopts it.

## Consequences

- the initial installer path stays close to Debian;
- the live and installed filesystem use the same ECZOS package set;
- installer selection remains reversible before the first public release;
- installer UX branding is not yet complete.
