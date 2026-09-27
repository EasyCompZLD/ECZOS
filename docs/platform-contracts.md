# ECZOS platform contracts

ECZOS features use one lifecycle: detection, capability, dependency,
configuration, verification, monitoring and recovery. A feature reports a
machine-readable capability result before it proposes a configuration change.

`eczos-capability` emits version 1 of this result. `status` describes the user
impact while `reason` is a stable, untranslated identifier for Settings and
support tooling. Human-readable translations belong in the caller.

System configuration migrations are package-owned executables below
`/usr/lib/eczos/migrations.d/<component>/`. Their names use
`NNNN-lowercase-name`. `eczos-config-migrate run` executes every pending
migration under a global lock, records its checksum and completion time below
`/var/lib/eczos/migrations/`, and refuses to continue if an already applied
migration was modified. A released migration is therefore immutable; fixes are
new, idempotent migrations.
