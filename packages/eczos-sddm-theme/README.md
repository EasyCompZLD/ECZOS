# eczos-sddm-theme

This package activates the ECZOS SDDM presentation without copying or replacing
Debian/KDE-owned Breeze files.

The theme depends on Debian's `sddm-theme-breeze` package and links its QML
implementation into the `eczos` theme directory. ECZOS owns only its metadata,
theme settings and SDDM selection snippet. Branding images remain owned by the
separate `eczos-branding` package.

Removing or purging this package removes the ECZOS theme selection and lets SDDM
fall back to the remaining distribution configuration.
