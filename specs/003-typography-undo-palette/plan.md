# Implementation Plan: Typography, Per-Phase Undo & Calm Color Palette

**Branch**: `003-typography-undo-palette` | **Date**: 2026-06-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-typography-undo-palette/spec.md`

## Summary

Three coordinated UX improvements to the Werewolf moderator app:

1. **Per-phase undo (P1)** — a unified, snapshot-based undo that lets the moderator revert the most recent reversible action at any phase (wolf kill, bodyguard protect, witch save/kill, seer check, day nomination/vote, phase advancement). Implemented as an in-memory snapshot history stack inside `GameNotifier` that captures both the immutable `GameSession` and the transient `_pendingNight` record before every mutation; undo pops and restores. This subsumes the existing `undoLastDeath`.
2. **Calm color palette (P2)** — replace the current multi-color theme (gold/violet/emerald/cyan/amber + rainbow gradients) with a neutral black/white/grey base plus exactly two accent colors (red = danger/death, yellow = warning/highlight). Provide **both light and dark variants** with a persisted moderator-controlled toggle. Roles are differentiated by icon/label/grouping instead of unique colors.
3. **Improved typography (P3)** — a single, consistent type scale with full Vietnamese diacritic support, replacing the current Cinzel + Nunito pairing where legibility/diacritics are weak.

All three are presentation/state-management changes; no game rules change. Existing tests must continue to pass and a 7–8 player game must run start-to-end with zero errors.

## Technical Context

**Language/Version**: Dart 3.8.1 / Flutter 3.32.7 (stable)

**Primary Dependencies**: flutter_riverpod ^2.5.1 (state), google_fonts ^6.2.1 (typography), shared_preferences ^2.3.2 (persistence), uuid, confetti

**Storage**: `shared_preferences` (key/value). Active game session is JSON-serialized via `PersistenceService`. Theme-mode preference will be persisted the same way. Undo history is **in-memory only** (per session, not persisted).

**Testing**: `flutter_test` + Riverpod `ProviderContainer`. Existing suites: `test/game_notifier_test.dart` (provider/state logic), `test/widget_test.dart`.

**Target Platform**: iOS and Android phones (portrait-locked). Recently validated on iOS Simulator.

**Project Type**: Single-project Flutter mobile app (`lib/` + `test/`).

**Performance Goals**: 60 fps UI; undo restores state in a single synchronous frame (< 5 s and ≤ 2 taps per SC-002).

**Constraints**: Offline-capable single-device tool; undo history bounded (cap ~50 snapshots) to keep memory negligible; theme switch must re-render the whole app instantly and persist across restarts.

**Scale/Scope**: ~7 screens (home, setup, role assignment, game master, night action, day voting, win/end), ~8 widget files. Typography is centralized (12 `GoogleFonts` call sites, all in `lib/theme/app_theme.dart`). Color/gradient usage spans 8 files (`AppGradients` in 8, per-role color tokens in 5).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The project constitution (`.specify/memory/constitution.md`) is an unpopulated template with no ratified principles. There are therefore no concrete gates to enforce. Applying sensible defaults consistent with the existing codebase:

- **Simplicity**: Reuse existing patterns (immutable `copyWith` models, Riverpod `StateNotifier`, centralized `AppTheme`). The undo feature adds one snapshot stack rather than per-action inverse logic — the simplest robust option. ✅
- **Test continuity**: All existing tests must keep passing; new provider-level tests added for undo (FR-019). ✅
- **No new heavy dependencies**: Typography stays on `google_fonts`; theming stays on `ThemeData`; persistence reuses `shared_preferences`. No new packages required. ✅

**Result**: PASS (no violations; Complexity Tracking section left empty).

## Project Structure

### Documentation (this feature)

```text
specs/003-typography-undo-palette/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (UI/state contracts)
│   ├── undo-contract.md
│   └── theme-contract.md
└── checklists/
    └── requirements.md  # From /speckit-specify
```

### Source Code (repository root)

```text
lib/
├── main.dart                       # MODIFY: add darkTheme + themeMode wired to provider
├── theme/
│   ├── app_theme.dart              # MODIFY: rebuild as light+dark from semantic palette + type scale
│   ├── app_colors.dart             # NEW: semantic palette tokens (base/surface/text/danger=red/warning=yellow), light & dark
│   ├── app_typography.dart         # NEW: named type-scale tokens (display/heading/title/body/label)
│   └── app_gradients.dart          # MODIFY/REMOVE: neutralize or delete saturated gradients
├── providers/
│   ├── game_provider.dart          # MODIFY: add snapshot undo stack; route mutations through _pushSnapshot(); undo()/canUndo
│   ├── theme_provider.dart         # NEW: ThemeMode StateNotifier persisted via prefs
│   └── persistence_service.dart    # MODIFY: add theme-mode load/save helpers
├── widgets/
│   ├── undo_button.dart            # NEW: shared undo control (disabled when canUndo == false)
│   ├── role_card_widget.dart       # MODIFY: drop per-role colors → icon/label/grouping
│   ├── atmospheric_background.dart # MODIFY: neutral background
│   └── countdown_timer.dart        # MODIFY: palette tokens
└── screens/
    ├── home_screen.dart            # MODIFY: theme toggle entry point + palette
    ├── setup/role_assignment_screen.dart  # MODIFY: palette + undo where applicable
    └── game/
        ├── game_master_screen.dart # MODIFY: replace undoLastDeath wiring w/ unified undo; palette
        ├── night_action_screen.dart# MODIFY: add undo control; palette
        ├── day_voting_screen.dart  # MODIFY: add undo control; palette
        ├── role_reference_panel.dart # MODIFY: palette/role differentiation
        └── rules_panel.dart        # MODIFY: palette

test/
├── game_notifier_test.dart         # MODIFY/ADD: undo snapshot tests across phases (FR-001..009)
├── theme_provider_test.dart        # NEW: theme-mode persistence/toggle
└── widget_test.dart                # MODIFY: smoke test under new theme
```

**Structure Decision**: Single-project Flutter app. The feature touches three concerns kept in their existing homes: state/undo in `lib/providers/`, visual system in `lib/theme/`, and per-screen wiring in `lib/screens/` + `lib/widgets/`. New files isolate the additive pieces (semantic palette, type scale, theme-mode provider, shared undo button) so existing code is modified minimally and the design stays reviewable.

## Complexity Tracking

> No constitution violations. Section intentionally empty.
