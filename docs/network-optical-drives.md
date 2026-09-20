# ECZOS Network Optical Drives

ECZOS Settings can expose a physical CD, DVD or Blu-ray drive to another
ECZOS computer on the same private network. The receiving computer sees a real
SCSI optical block device (`/dev/srN`), so existing Linux applications do not
need an ECZOS-specific virtual-file interface.

## Components

The feature is split across narrow components:

- the native ECZOS Settings page presents local and discovered drives;
- `/usr/bin/eczos-network-optical` performs unprivileged, read-only hardware,
  DNS-SD and iSCSI status discovery and emits versioned JSON;
- `/usr/lib/eczos-network-optical/helper` performs individual privileged
  operations after Polkit authorization;
- Linux LIO with an rtslib-fb pSCSI backstore exports the physical drive;
- Open-iSCSI creates the remote SCSI device on the client;
- Avahi advertises and discovers `_eczos-optical._tcp` services; and
- `eczos-network-optical-guard.service` maintains the one-client claim.

No GUI process runs as root. The helper accepts only validated devices,
private-LAN endpoints, port 3260 and syntactically valid IQNs; it does not
accept shell commands. Persistent server state lives in
`/var/lib/eczos/network-optical/state.json`. Open-iSCSI stores client nodes and
their manual or automatic startup policy in its normal system configuration.

## Sharing and discovery

Only physical optical drives found as `/dev/srN` with udev optical-drive
properties can be shared. iSCSI-backed drives are explicitly excluded to avoid
sharing a remote drive again. Each drive receives a stable identifier derived
from stable udev identity data and a stable ECZOS IQN derived from the machine
identity and drive identifier.

Sharing is explicit and initially open for one initiator to claim. The guard
records the first active iSCSI initiator, disables dynamic ACL generation and
removes competing ACLs. After that client disconnects, the claim is retained
for a configurable grace period (30 seconds by default) and then released.
This provides LAN convenience and collision prevention; it is not a substitute
for network isolation or authenticated storage. ECZOS therefore binds only to
a private address and never presents the feature as internet-safe.

Automatic client connection is off by default. A user can enable it per drive
from ECZOS Settings, and the displayed switch is read back from Open-iSCSI
rather than being transient GUI state.

## Failure and recovery behaviour

- Disconnect refuses while the device is busy, unmounts mounted media through
  UDisks, flushes writes and waits for the `/dev/srN` device to disappear.
- Stopping a share refuses while a client session is active unless the
  explicit maintenance-only force option is used.
- Eject refuses while the drive is busy and unmounts mounted media first.
- If Avahi is unavailable, local drives remain visible and manageable; network
  discovery returns an empty list instead of inventing cached devices.
- Advanced details expose the device, SCSI generic node, IQN, port and backend
  for support without placing those details in the normal workflow.

## Known boundary for the first release

The first-client claim is enforced by a local guard after LIO creates a dynamic
ACL. Two clients attempting their very first login within the same short guard
interval are an edge-case race. Normal later competitors are rejected. A
future pairing protocol with per-client CHAP credentials can close that initial
claim window; the current implementation must not be described as hostile-LAN
security.

## Operator CLI

The supported read-only inspection commands are:

```sh
eczos-network-optical list-local --json
eczos-network-optical list-network --json
eczos-network-optical status --json
```

Privileged helper calls are an internal interface used through Polkit by ECZOS
Settings. They are intentionally not advertised as an end-user shell workflow.
