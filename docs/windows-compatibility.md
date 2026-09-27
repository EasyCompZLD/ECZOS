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

Schema 2 stores a runner profile, Windows version and architecture, dependency
records, environment variables, DLL overrides, graphics, audio, MIDI and launch
configuration. ECZOS migrates schema-1 records atomically and retains their
existing prefix. Application-specific workarounds belong in declarative data,
not hard-coded GUI branches.

## Managed components

Optional Windows components are declared below
`/usr/share/eczos/windows/dependencies/`. ECZ Windows validates every definition,
queries the selected application's existing prefix and installs a missing
component only after confirmation. Successful operations are recorded in the
schema-2 application record and in a private per-application log. Normal
application launches never run Winetricks, Wineboot or dependency detection.

The initial reviewed catalogue covers Visual C++ 2015–2022, .NET Framework 4.8,
Core Fonts, DirectPlay, DXVK, VKD3D, MSXML 6 and the Direct3D 47 compiler. These
are optional per-application choices rather than global promises of
compatibility.

Legacy optical media may start a promotional wrapper rather than the real game
installer. ECZ Windows recognizes the constrained `Now.ini` format used by
Sold Out Software discs, validates that its `[Setup] EXE=` target remains
inside the copied medium and launches that target directly. This avoids
installing retired Internet Explorer, Flash or Shockwave browser plug-ins just
to display an obsolete disc menu. The fallback is deliberately data-driven and
does not guess arbitrary executables.

## Runtime policy

- Ordinary applications default to a tested Wine runtime.
- Steam games use Steam-managed Proton where applicable.
- Non-Steam games may use Proton through a reviewed UMU integration.
- DXVK/VKD3D and gaming options are applied per application.
- Runtime choice is automatic by default and overridable in an advanced view.
- Wine-GE is not a runner target because that project is archived; reviewed
  non-Steam game profiles use UMU with UMU-Proton or GE-Proton instead.

ECZOS does not promise universal compatibility. Status values must distinguish
tested, expected, unknown and unsupported software.

## Drive policy

- `C:` is the private application prefix.
- A user-selected shared folder may be presented as `H:`.
- Removable media and network shares require explicit grants.
- No default `Z:` mapping exposes the Linux root.
