# eczos-release

This package exposes ECZOS as the human-facing product identity. It preserves
Debian's canonical `/usr/lib/os-release`, diverts and restores the conventional
`/etc/os-release` compatibility symlink, and keeps `ID=debian` plus the Debian
version and codename for software detection. ECZOS-specific metadata also lives
in `/usr/lib/eczos/release/eczos-release` and is shown by `eczos-info`.
