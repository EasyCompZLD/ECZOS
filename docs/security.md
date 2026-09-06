# Security architecture

## Remote support

Remote support must use per-device enrollment and revocable credentials. It is
optional, visibly controllable by the user and never required for boot. No image
or package may contain a shared unattended-access password.

The legacy ECZHOA/RustDesk binary is quarantined by repository policy and must
not be reused until its credential has been rotated and its package provenance,
maintainer scripts and update path have been reviewed.

## Windows executables

Wine is a compatibility layer, not a security boundary. Opening `.exe` or `.msi`
files must go through an ECZOS trust and inspection workflow. ECZOS must not use
an automatic binary-format handler that silently executes downloads.

Each managed Windows application receives a separate prefix and application
identity. Default drive mappings expose only the prefix and explicitly approved
locations. The Linux root and complete user home are not mapped by default.

## Runtime supply chain

Runtime downloads must use HTTPS, pinned versions, recorded checksums and a
verifiable publisher. Runtime rollback must be possible. Proton-GE and UMU are
never fetched through an unreviewed `curl | shell` workflow.

## Privilege boundary

Windows applications and ECZOS desktop tools run unprivileged. A small privileged
helper may exist later for narrowly defined package or system operations, using
polkit and explicit authorization. It must not accept arbitrary commands or
paths from an unprivileged caller.
