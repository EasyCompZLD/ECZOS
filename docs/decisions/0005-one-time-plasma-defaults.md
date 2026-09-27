# ADR 0005 — Plasma defaults apply once per user

## Status

Accepted on 2026-09-06.

## Decision

ECZOS desktop defaults run once from KDE autostart and create a versioned marker
below the user's XDG state directory only after successful application. Later
logins do not reapply the same version. New profiles start in `nightlight` mode;
the original primary blue wallpaper remains available as the legacy `default`
mode. A user can deliberately select `nightlight`, `light` or `dark` with
`eczos-theme-switch`, or cycle the alternate modes with
`eczos-theme-toggle`.

The `nightlight` appearance follows KWin's live Night Light state over D-Bus.
It does not maintain a second ECZOS clock. Scheduled and location-based Night
Light therefore switch the appearance at the same transition, while manually
disabling or inhibiting Night Light immediately restores the light appearance.
The historical `auto` value is accepted and migrated as a compatibility alias.

The first version keeps Plasma's standard bottom panel. Plasma 6 already exposes
the familiar application launcher, task manager, system tray and clock in that
layout, so ECZOS does not replace or copy Debian's Plasma shell implementation.

## Consequences

- existing user changes survive future logins;
- incrementing the marker version provides an explicit migration mechanism;
- package removal does not delete user configuration or state;
- additional layout changes require a separately reviewed migration.
