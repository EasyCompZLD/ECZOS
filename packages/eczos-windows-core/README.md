# eczos-windows-core

This package is the first safe ECZ Windows MVP. It registers ECZOS as the
desktop handler for `.exe` and `.msi`, asks before execution, records a SHA-256
digest, creates an isolated Wine prefix per application and removes Wine's
default `Z:` mapping to the Linux root. It also removes prefix symlinks that
point outside that prefix. This reduces accidental file exposure but is not a
sandbox; the confirmation dialog states that distinction explicitly.

`eczos-windows list`, `info`, `run`, `repair` and `remove` manage application
records. A visible **ECZ Windows-apps** menu entry provides the initial graphical
management view. Installers run from an internal `C:\ECZOS-Install` directory,
so removing Wine's Linux-root mapping does not prevent them from starting.

The first version uses Debian's system Wine through an ECZ runtime adapter.
Both the 64-bit and i386 Wine runtimes are required because many Windows
installers remain 32-bit. The dedicated host helper enables Debian multiarch and
installs that i386 runtime before compatibility testing.
Versioned runtime downloads, advanced installer discovery, real icon extraction,
DXVK and Proton are later gates.
