---
description: "Task list for Typography, Per-Phase Undo & Calm Color Palette"
---

# Tasks: Typography, Per-Phase Undo & Calm Color Palette

**Input**: Design documents from `/specs/003-typography-undo-palette/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — `research.md` R4 defines a test strategy and FR-019/SC-007 require the existing suite to stay green plus new undo/theme coverage.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All paths are relative to repository root (`/Users/tienhoang1211/repos/boardgame_master`)

## Path Conventions

Single-project Flutter app: source in `lib/`, tests in `test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish a known-good starting point before any change.

- [X] T001 Run `flutter pub get` and confirm the project builds in `/Users/tienhoang1211/repos/boardgame_master`
- [X] T002 Capture baseline: run `flutter analyze` and `flutter test` and confirm both are green before changes
- [X] T003 [P] Spike: confirm `GoogleFonts.beVietnamPro` is available via the existing `google_fonts` dependency (no pubspec/asset changes needed)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Cross-cutting prerequisites that must hold before story work begins.

**⚠️ CRITICAL**: Complete before starting any user story.

- [X] T004 Confirm the green baseline from T002 is the reference for FR-019/SC-007 (no story may regress it)

**Checkpoint**: Foundation ready. User Story 1 (the MVP) has no further dependencies and can begin. US2 and US3 are independent of US1 but US3 builds on the theme structure introduced in US2.

---

## Phase 3: User Story 1 - Undo a Mistaken Pick at Any Phase (Priority: P1) 🎯 MVP

**Goal**: A unified, snapshot-based undo lets the moderator revert the most recent reversible action at every phase (wolf kill, bodyguard, witch save/kill, seer, nomination, vote-count, phase advance, deaths), with win-condition re-evaluation and `_pendingNight` consistency. Subsumes `undoLastDeath`.

**Independent Test**: In a 7–8 player game, make a wrong pick in each interactive phase, tap Undo, and confirm state returns to exactly before the pick; undo a phase-advance returns to the previous phase; undo a win-triggering death clears the win.

### Tests for User Story 1 ⚠️ (write first, expect FAIL)

- [X] T005 [US1] Add undo unit tests in `test/game_notifier_test.dart` covering: undo clears just-selected wolf/bodyguard/witch/seer target (U1); repeated undo reverts in reverse order until empty (U2/U4); `canUndo` false on fresh game (U3); undo of `nextPhase` restores previous phase with actions intact (U5); undo of a win-triggering death restores `result` to ongoing and revives player (U6/U8); undo touches only derived state (U7)

### Implementation for User Story 1

- [X] T006 [US1] Add `UndoSnapshot` (captures `GameSession` + transient `_pendingNight`) and an in-memory `_undoStack` with cap (~50) to `GameNotifier` in `lib/providers/game_provider.dart`
- [X] T007 [US1] Add `_pushSnapshot()`, `bool get canUndo`, and `void undo()` (pop → restore session + `_pendingNight` → `_save()`) to `lib/providers/game_provider.dart`
- [X] T008 [US1] Route every mutator through `_pushSnapshot()` first in `lib/providers/game_provider.dart` (`nextPhase`, `prevPhase`, `killPlayer`, `revivePlayer`, `recordWolfKill`, `recordBodyguardProtect`, `recordWitchSave`, `recordWitchKill`, `clearWitchKill`, `recordSeer`, `resolveNight`, `recordHunterShot`, `nominatePlayer`, `setVoteCount`, `resolveVote`, `confirmExecution`, `nextRound`); exclude `beginNightAction`, `_save`, pure getters
- [X] T009 [US1] Remove/redirect `undoLastDeath` to the unified `undo()` and clear `_undoStack` in `startGame()`/`endGame()` in `lib/providers/game_provider.dart`
- [X] T010 [P] [US1] Create shared `UndoButton` widget in `lib/widgets/undo_button.dart` that watches `canUndo` (disabled/hidden when false) and calls `undo()`, with an outlined undo icon + label
- [X] T011 [US1] Wire `UndoButton` into `lib/screens/game/night_action_screen.dart` (revert wolf/bodyguard/witch/seer picks before commit)
- [X] T012 [US1] Wire `UndoButton` into `lib/screens/game/day_voting_screen.dart` (revert nomination / vote-count entry)
- [X] T013 [US1] Replace the existing `undoLastDeath` button with `UndoButton`/unified `undo()` in `lib/screens/game/game_master_screen.dart` and ensure restored state reflects immediately in alive/dead lists
- [X] T014 [US1] Run `flutter test` and confirm T005 tests pass and no prior test regressed

**Checkpoint**: US1 fully functional and independently testable — the MVP. Undo works in 100% of interactive phases (SC-001) in ≤ 2 taps (SC-002).

---

## Phase 4: User Story 2 - Calm, Consistent Color Palette (Priority: P2)

**Goal**: Replace the multi-color theme with a neutral black/white/grey base + exactly red (danger) and yellow (warning/highlight), offered as light AND dark variants with a persisted toggle; roles differentiated by icon/label/grouping.

**Independent Test**: Every screen shows only neutral + red + yellow; toggling light/dark re-skins the whole app and persists across restart; roles distinguishable without color.

### Tests for User Story 2 ⚠️

- [X] T015 [US2] Add `test/theme_provider_test.dart` verifying `themeModeProvider` defaults to `system`, `setMode()` updates state, and the choice persists/restores via `shared_preferences` (use `SharedPreferences.setMockInitialValues`)

### Implementation for User Story 2

- [X] T016 [P] [US2] Create semantic palette tokens (light + dark variants: background/surface/surfaceVariant/textPrimary/textSecondary/outline/danger=red/warning=yellow/onAccent) in `lib/theme/app_colors.dart`
- [X] T017 [US2] Rebuild `lib/theme/app_theme.dart` to expose `AppTheme.light` and `AppTheme.dark` `ThemeData` built from `app_colors.dart`; remove per-role color tokens (`wolfCrimson`, `seerViolet`, `witchEmerald`, `bodyguardCyan`, `hunterAmber`, `foolYellow`)
- [X] T018 [P] [US2] Neutralize or remove saturated/role gradients in `lib/theme/app_gradients.dart` (delete `AppGradients.role` and rainbow scene gradients)
- [X] T019 [P] [US2] Create `themeModeProvider` (`StateNotifier<ThemeMode>`, loads persisted value on init, `setMode()` persists) in `lib/providers/theme_provider.dart`
- [X] T020 [US2] Add theme-mode load/save helpers (key `'theme_mode'`) to `lib/providers/persistence_service.dart`
- [X] T021 [US2] Wire `MaterialApp` with `theme: AppTheme.light`, `darkTheme: AppTheme.dark`, `themeMode:` from provider in `lib/main.dart`
- [X] T022 [US2] Add a light/dark toggle entry point in `lib/screens/home_screen.dart` and apply palette tokens
- [X] T023 [US2] Replace per-role colors with icon + label + grouping in `lib/widgets/role_card_widget.dart`
- [X] T024 [P] [US2] Apply palette tokens (red=danger, yellow=highlight; each color state also carries icon/label) in `lib/screens/game/game_master_screen.dart`
- [X] T025 [P] [US2] Apply palette tokens in `lib/screens/game/night_action_screen.dart`
- [X] T026 [P] [US2] Apply palette tokens in `lib/screens/game/day_voting_screen.dart`
- [X] T027 [P] [US2] Apply palette tokens in `lib/screens/game/role_reference_panel.dart`
- [X] T028 [P] [US2] Apply palette tokens in `lib/screens/game/rules_panel.dart`
- [X] T029 [P] [US2] Apply palette tokens in `lib/screens/setup/role_assignment_screen.dart`
- [X] T030 [P] [US2] Apply palette tokens in `lib/widgets/atmospheric_background.dart` and `lib/widgets/countdown_timer.dart`
- [X] T031 [US2] Run `flutter test` (incl. T015) and audit every screen: only neutral + red + yellow remain, no out-of-palette token or rainbow gradient (SC-003/SC-004)

**Checkpoint**: US1 + US2 both work independently; app has a coherent 2-accent palette with a persisted light/dark toggle.

---

## Phase 5: User Story 3 - Improved, Legible Typography (Priority: P3)

**Goal**: A single consistent type scale (Be Vietnam Pro) mapped to `TextTheme`, legible at arm's length with full Vietnamese diacritic support.

**Independent Test**: Every screen uses the consistent scale with clear hierarchy; player names/instructions legible at arm's length; Vietnamese diacritics render correctly with no clipping.

**Note**: Builds on the theme structure from US2 (T017). If run before US2, integrate the scale into the existing `AppTheme` instead.

### Implementation for User Story 3

- [X] T032 [P] [US3] Create named type-scale tokens (display/headline/title/body/bodySmall/label using Be Vietnam Pro via `google_fonts`) in `lib/theme/app_typography.dart`
- [X] T033 [US3] Integrate the type scale into the `TextTheme` of `AppTheme.light` and `AppTheme.dark` in `lib/theme/app_theme.dart`; remove the old `cinzelDisplay`/`nunitoBody` helpers (or repoint them to the scale)
- [X] T034 [US3] Replace ad-hoc/`GoogleFonts.cinzel`/`GoogleFonts.nunito` text styles with `Theme.of(context).textTheme` slots across all screens/widgets that set explicit fonts (game_master, night_action, day_voting, role_reference_panel, rules_panel, role_assignment, home, role_card_widget, countdown_timer)
- [X] T035 [US3] Verify Vietnamese diacritics and no-clipping on every screen at phone sizes (manual review + add a widget smoke assertion if practical) (FR-017/FR-018, SC-005/SC-006)

**Checkpoint**: All three stories independently functional; typography consistent and legible in both palette modes.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation across all stories.

- [X] T036 Update `test/widget_test.dart` smoke test to build under the new `MaterialApp` theme/themeMode wiring
- [X] T037 Run `flutter analyze` (clean) and `flutter test` (all pass) — SC-007
- [X] T038 Run the full `quickstart.md` manual walkthrough: 7–8 player game start → clean win with zero errors, undo in each phase, light/dark toggle + persistence, palette + Vietnamese audit (SC-001…SC-007)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: After Setup — establishes the green baseline gate
- **User Stories (Phase 3+)**: After Foundational
  - **US1 (P1)** is fully independent — the MVP
  - **US2 (P2)** is independent of US1
  - **US3 (P3)** is independent of US1 but builds on the theme structure from US2 (T017); if done standalone, integrate into the current `AppTheme`
- **Polish (Phase 6)**: After the desired stories are complete

### Within Each User Story

- Tests (US1 T005, US2 T015) written first and expected to fail before implementation
- Tokens/models before theme wiring before per-screen rollout
- US1: provider snapshot API (T006–T009) before UI wiring (T010–T013) before test confirmation (T014)
- US2: tokens (T016) before theme rebuild (T017) before provider/persistence (T019–T020) before MaterialApp wiring (T021) before per-screen rollout (T023–T030)

### Parallel Opportunities

- **Setup**: T003 in parallel with T001/T002 prep
- **US1**: T010 (new widget file) parallel with provider work; T011–T013 are different screen files but each depends on the provider API (T006–T009) being done
- **US2**: T016, T018, T019 in parallel (different new files); per-screen palette rollout T024–T030 in parallel once T017 lands
- **US3**: T032 parallel to other token work
- **Cross-story**: with multiple developers, US1 and US2 can proceed fully in parallel after Foundational

---

## Parallel Example: User Story 2

```bash
# After T015 test is written, create independent new files in parallel:
Task: "Create lib/theme/app_colors.dart semantic tokens (T016)"
Task: "Neutralize lib/theme/app_gradients.dart (T018)"
Task: "Create lib/providers/theme_provider.dart (T019)"

# After T017 (theme rebuild) lands, roll out palette across screens in parallel:
Task: "Apply palette in lib/screens/game/game_master_screen.dart (T024)"
Task: "Apply palette in lib/screens/game/night_action_screen.dart (T025)"
Task: "Apply palette in lib/screens/game/day_voting_screen.dart (T026)"
Task: "Apply palette in lib/screens/game/role_reference_panel.dart (T027)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup → Phase 2: Foundational
2. Phase 3: US1 (per-phase undo)
3. **STOP and VALIDATE**: play a game, undo in every phase, confirm tests green
4. Ship the MVP — the highest-value safety net

### Incremental Delivery

1. Setup + Foundational → baseline green
2. US1 (undo) → test independently → ship (MVP!)
3. US2 (palette + light/dark) → test independently → ship
4. US3 (typography) → test independently → ship
5. Polish → full quickstart validation

### Parallel Team Strategy

After Foundational: Developer A → US1; Developer B → US2 (tokens/theme/toggle); then US3 follows US2's theme rebuild. Each story integrates without breaking the others.

---

## Notes

- [P] = different files, no incomplete dependencies
- [Story] label maps each task to US1/US2/US3 for traceability
- Undo is a single snapshot mechanism (data-model §1–2) — do not write per-action inverse logic
- Palette must keep exactly one red + one yellow; color is never the sole signal (theme-contract P2/P6)
- Commit after each task or logical group; stop at any checkpoint to validate a story independently
