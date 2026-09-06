# ECZ Windows architecture

ECZ Windows makes supported Windows applications feel managed and native without
presenting Wine terminology as a prerequisite.

## MVP workflow

```text
Open .exe/.msi
  → inspect type, origin and trust
  → obtain explicit confirmation
  → create application record and isolated prefix
  → select a tested Wine runtime
  → run installer
  → discover installed entry points and icons
  → create ECZOS-owned desktop integration
  → launch, diagnose, repair or remove through the same application record
```

Filename heuristics such as `setup.exe` may contribute evidence but are not
sufficient for classification. PE metadata, MSI metadata, registry entries and
installer results should be used where available.

## State

Per-user application state belongs below:

```text
~/.local/share/eczos/windows/apps/<application-id>/
```

System-provided declarative profiles belong below:

```text
/usr/share/eczos/windows/profiles/
```

The schema will be versioned before the first persistent application record is
created. Application-specific workarounds belong in data, not hard-coded GUI
branches.

## Runtime policy

- Ordinary applications default to a tested Wine runtime.
- Steam games use Steam-managed Proton where applicable.
- Non-Steam games may use Proton through a reviewed UMU integration.
- DXVK/VKD3D and gaming options are applied per application.
- Runtime choice is automatic by default and overridable in an advanced view.

ECZOS does not promise universal compatibility. Status values must distinguish
tested, expected, unknown and unsupported software.

## Drive policy

- `C:` is the private application prefix.
- A user-selected shared folder may be presented as `H:`.
- Removable media and network shares require explicit grants.
- No default `Z:` mapping exposes the Linux root.
