# Security architecture

## Host firewall

ECZOS installs and enables `firewalld` with its nftables backend. The default
`eczos-public` workstation zone blocks unsolicited inbound connections while
allowing DHCPv6, link-local mDNS discovery and KDE Connect. Administrators can
review and change zones and services through the Firewall page embedded in
ECZOS Settings.

An update to an existing machine preserves SSH only when the SSH service was
already explicitly enabled. Fresh installations do not expose SSH by default.
The network-optical-drive service opens TCP 3260 only while a user has an
active exported drive and closes it when the final share is removed. Remote
support remains an outbound client workflow and does not receive a blanket
inbound firewall exception.

## Remote support

Remote support must use per-device enrollment and revocable credentials. It is
optional, visibly controllable by the user and never required for boot. No image
or package may contain a shared unattended-access password.

The legacy ECZHOA/RustDesk binary is quarantined by repository policy and must
not be reused until its credential has been rotated and its package provenance,
maintainer scripts and update path have been reviewed.

RustDesk-derived ECZHOA builds use software video encoding by default. Hardware
encoding is an optional performance feature, not a requirement for remote
support: a failing AMD VCE/VCN encoder can otherwise reset the graphics card and
terminate the entire Plasma X11 session. The ECZOS remote-support guard changes
only `enable-hwcodec`; it must preserve the device identity, server address and
access credentials already stored in each RustDesk profile.

## Windows executables

Wine is a compatibility layer, not a security boundary. Opening `.exe` or `.msi`
files must go through an ECZOS trust and inspection workflow. ECZOS must not use
an automatic binary-format handler that silently executes downloads.

Each managed Windows application receives a separate prefix and application
identity. Default drive mappings expose only the prefix and explicitly approved
locations. The Linux root and complete user home are not mapped by default.
PE icon extraction invokes the native resource parsers inside a Bubblewrap
sandbox without network or access to the user's files. Failure falls back to a
generic icon and must never block installation or launch.

## Runtime supply chain

Runtime downloads must use HTTPS, pinned versions, recorded checksums and a
verifiable publisher. Runtime rollback must be possible. Proton-GE and UMU are
never fetched through an unreviewed `curl | shell` workflow.

FreeOffice is obtained from SoftMaker's HTTPS APT repository with a repository-
scoped signing key. ECZOS pins the reviewed key bytes and limits that repository
to the FreeOffice package so it cannot replace Debian packages unexpectedly.

## Privilege boundary

Windows applications and ECZOS desktop tools run unprivileged. A small privileged
helper may exist later for narrowly defined package or system operations, using
polkit and explicit authorization. It must not accept arbitrary commands or
paths from an unprivileged caller.

The network-optical-drive helper is the first implementation of this boundary.
It accepts only enumerated operations and validated optical devices, IQNs and
private-LAN endpoints. The GUI and read-only discovery CLI stay unprivileged.
The first-client LIO claim prevents normal concurrent use but is not strong
authentication; the feature must be used only on a trusted private LAN. Its
initial dynamic-ACL claim interval is documented in
`docs/network-optical-drives.md` and must not be marketed as hostile-LAN
protection.
