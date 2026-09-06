# ADR 0003: ECZOS SDDM theme inherits Debian Breeze implementation

Status: accepted

## Context

The historical `easycomp` theme contains a customized `theme.conf`. Its QML,
fallback logo, preview and metadata were otherwise copied byte-for-byte from the
Debian Trixie Breeze SDDM theme.

## Decision

`eczos-sddm-theme` owns the ECZOS metadata, configuration and selection snippet.
It depends on `sddm-theme-breeze` and uses package-managed symlinks for the QML
implementation. Branding images come from `eczos-branding`.

## Consequences

KDE security and compatibility updates remain owned by Debian. ECZOS does not
carry an unnecessary QML fork or duplicated translations. The theme package can
be purged without modifying files owned by SDDM, Plasma or Breeze.
