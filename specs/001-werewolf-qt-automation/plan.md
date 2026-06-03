# Implementation Plan: Werewolf QT Automation

**Branch**: `001-werewolf-qt-automation` | **Date**: 2026-05-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-werewolf-qt-automation/spec.md`

---

## Summary

Transform the existing phase-navigator skeleton into a fully automated Werewolf moderator assistant. The QT needs zero game knowledge: the app provides exact narration scripts, records all night actions, resolves interactions automatically, manages day voting, tracks consumable abilities, and auto-detects win conditions. Locally persisted state survives app restarts. An in-game role reference panel allows QT to look up any skill mid-game without interrupting flow.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (SDK `>=3.0.0 <4.0.0`)

**Primary Dependencies**:
- `flutter_riverpod: ^2.5.1` — state management (already in use)
- `uuid: ^4.4.0` — player ID generation (already in use)
- `shared_preferences: ^2.x` — local JSON persistence (to be added)

**Storage**: Local device storage via `shared_preferences`; full game state serialized as JSON on every mutation.

**Testing**: `flutter_test` (already configured); no additional test packages needed for this feature.

**Target Platform**: Android (primary) + iOS. Portrait orientation enforced at app start. Android Studio as IDE.

**Project Type**: Single Flutter mobile app — no backend, no networking.

**Performance Goals**: All state transitions complete within one frame (16ms); no loading spinners needed.

**Constraints**: Fully offline; single-device (QT only); portrait orientation only.

**Scale/Scope**: 5–20 players; 7 roles; ~6 new screens/panels; ~8 new/extended models.

---

## Constitution Check

Constitution file is a blank template — no project-specific gates are defined. No violations to track.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-werewolf-qt-automation/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output (includes Android Studio setup)
├── contracts/
│   └── ui-contracts.md  ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code Layout

```text
lib/
├── main.dart                              (unchanged)
├── theme/
│   └── app_theme.dart                     (unchanged)
├── games/
│   └── werewolf/
│       ├── werewolf_game.dart             (extend: autoDistribute, buildRoundPhases enhanced)
│       ├── werewolf_roles.dart            (unchanged)
│       └── werewolf_presets.dart          (NEW: balanced preset table 5–20 players)
├── models/
│   ├── game_phase.dart                    (extend: add scriptText field)
│   ├── game_session.dart                  (extend: add abilityState, nightLog, voteTally)
│   ├── player.dart                        (unchanged)
│   ├── role.dart                          (unchanged)
│   ├── night_action_record.dart           (NEW)
│   ├── ability_state.dart                 (NEW)
│   └── vote_tally.dart                    (NEW)
├── providers/
│   ├── game_provider.dart                 (extend: night actions, voting, undo, persistence)
│   └── persistence_service.dart          (NEW: save/restore JSON to shared_preferences)
├── screens/
│   ├── home_screen.dart                   (unchanged)
│   ├── setup/
│   │   ├── player_setup_screen.dart       (unchanged)
│   │   └── role_assignment_screen.dart   (extend: add Auto-distribute button + balance badge)
│   └── game/
│       ├── game_master_screen.dart        (extend: add reference panel FAB, undo action)
│       ├── night_action_screen.dart       (NEW: per-role action recording with script)
│       ├── day_voting_screen.dart         (NEW: nomination + vote counter + tie prompt)
│       └── role_reference_panel.dart     (NEW: slide-up role encyclopedia)
└── widgets/
    ├── countdown_timer.dart               (unchanged)
    └── ability_status_widget.dart        (NEW: witch potions / ability chips display)

android/
└── app/
    └── src/main/res/                      (no changes needed; existing config valid)

test/
└── widget_test.dart                       (existing placeholder; no new tests in scope)
```

**Structure Decision**: Single Flutter project. No API layer. All new logic stays inside `lib/`. No new top-level folders.

---

## Implementation Sequence

Features are ordered by dependency. Each group can be started after the previous completes.

### Group 1 — Foundation models (no UI dependencies)

1. `ability_state.dart` — consumable ability flags
2. `night_action_record.dart` — per-round night action capture
3. `vote_tally.dart` — day vote tracking
4. `game_phase.dart` — add `scriptText` field
5. `werewolf_presets.dart` — balanced preset table
6. `persistence_service.dart` — JSON save/restore

### Group 2 — State layer extensions

7. `game_session.dart` — add `abilityState`, `nightLog`, `currentVoteTally`
8. `game_provider.dart` — add methods: `recordNightAction`, `resolveNight`, `recordVote`, `confirmExecution`, `triggerHunterShot`, `undoLastDeath`, `saveState`, `restoreState`
9. `werewolf_game.dart` — add `autoDistribute()`, enrich `buildRoundPhases` with scripts, add bodyguard constraint tracking

### Group 3 — New screens

10. `night_action_screen.dart` — guided night step with script card + action recording
11. `day_voting_screen.dart` — nomination chips + vote stepper + tie resolution
12. `role_reference_panel.dart` — draggable bottom sheet, role list, ability status

### Group 4 — Screen extensions

13. `role_assignment_screen.dart` — Auto-distribute button, balance status badge
14. `game_master_screen.dart` — wire night/day screens, add reference panel FAB, undo button

### Group 5 — Android Studio configuration

15. `android/` — verify `local.properties`; document run configuration in quickstart.md

---

## Complexity Tracking

No constitution violations. No complexity tracking required.
