# ADR 0005 — Plasma defaults apply once per user

## Status

Accepted on 2026-09-06.

## Decision

ECZOS desktop defaults run once from KDE autostart and create a versioned marker
below the user's XDG state directory only after successful application. Later
logins do not reapply the same version. The primary blue wallpaper is the
`default` mode. A user can deliberately select `auto`, `light` or `dark` with
`eczos-theme-switch`, or cycle the alternate modes with
`eczos-theme-toggle`.

The first version keeps Plasma's standard bottom panel. Plasma 6 already exposes
the familiar application launcher, task manager, system tray and clock in that
layout, so ECZOS does not replace or copy Debian's Plasma shell implementation.

## Consequences

- existing user changes survive future logins;
- incrementing the marker version provides an explicit migration mechanism;
- package removal does not delete user configuration or state;
- additional layout changes require a separately reviewed migration.
