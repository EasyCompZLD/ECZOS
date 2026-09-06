# eczos-release

This package exposes ECZOS product identity without modifying Debian's
`/etc/os-release`. Compatibility checks continue to see the real Debian base,
while ECZOS tools can read `/usr/lib/eczos/release/eczos-release` or run
`eczos-info`.
