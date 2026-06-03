# Contract: Theme, Palette & Typography

Defines what every screen and the theme system must honor for the palette (US2) and typography (US3).

## Palette contract

| ID | Requirement | Spec ref |
|---|---|---|
| P1 | Every widget references semantic tokens from `AppColors`/`Theme.of(context)`; no raw out-of-palette hex at call sites | FR-010, FR-011 |
| P2 | The only non-neutral colors rendered anywhere are `danger` (red) and `warning`/`highlight` (yellow) — exactly one shade each per mode | FR-010, FR-012 |
| P3 | Removed tokens: `wolfCrimson`, `seerViolet`, `witchEmerald`, `bodyguardCyan`, `hunterAmber`, `foolYellow`, and `AppGradients.role` + saturated scene gradients | FR-011 |
| P4 | Red = danger/death everywhere; yellow = warning/active-selection/highlight everywhere (consistent semantics across screens) | FR-012 |
| P5 | Roles distinguished by icon + label + grouping, never by a unique color | FR-013 |
| P6 | No state relies on color alone; each color-coded state also carries an icon or text label | FR-014, SC-004 |

## Theme-mode contract

| ID | Given | When | Then | Spec ref |
|---|---|---|---|---|
| T1 | App running | moderator selects light or dark | Entire app re-renders in that palette variant immediately | FR-014a |
| T2 | Mode changed | app restarted | Previously selected mode is restored from persistence | FR-014a |
| T3 | Either mode active | red/yellow accents shown | Same semantic meaning in both modes; contrast preserved against the base | FR-014a |
| T4 | `themeModeProvider` default | first ever launch | `ThemeMode.system` (follows device) | FR-014a |

### API
```text
ThemeData AppTheme.light    // neutral white-base + red/yellow accents
ThemeData AppTheme.dark     // neutral black-base + red/yellow accents
ThemeMode themeModeProvider // system | light | dark (persisted)
// MaterialApp: theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: <provider>
```

## Typography contract

| ID | Requirement | Spec ref |
|---|---|---|
| TY1 | All text styles come from a single type scale mapped to `TextTheme`; widgets read `Theme.of(context).textTheme` | FR-015 |
| TY2 | Chosen family renders Vietnamese diacritics with no clipping/substitution on every screen | FR-017, SC-006 |
| TY3 | Player names and current-phase instructions are legible at arm's length (title/body sizes) | FR-016, SC-005 |
| TY4 | No text clipped, overlapping, or overflowing on supported phone sizes under the new scale | FR-018, SC-005 |

## Cross-cutting

| ID | Requirement | Spec ref |
|---|---|---|
| X1 | All existing automated tests pass after changes | FR-019, SC-007 |
| X2 | A 7–8 player game runs start → clean end with zero errors | FR-019, SC-007 |
| X3 | Palette/typography/undo apply consistently across all screens (home, setup, role assignment, game master, night action, day voting, win/end) | FR-020 |
