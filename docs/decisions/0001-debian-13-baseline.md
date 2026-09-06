# ADR 0001: Debian 13 and Plasma 6 baseline

Status: accepted

## Decision

New ECZOS development targets Debian 13 (Trixie), amd64, KDE Plasma 6 and SDDM.
Debian 12/GNOME work is historical and is not the implementation baseline.

## Rationale

The most recent experimental ECZOS images already use Trixie and Plasma 6, and
the copied SDDM theme declares Qt 6. Debian 12 entered LTS in July 2026 and has a
shorter remaining support horizon for a new product.

## Consequences

All package and image tests must target Trixie. Supporting an existing Bookworm
installation requires a separately scoped compatibility branch and does not
change the main baseline.
