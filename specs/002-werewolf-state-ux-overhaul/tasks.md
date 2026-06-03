# Tasks: Werewolf App — State Fix & UX Overhaul

**Input**: Design documents from `/specs/002-werewolf-state-ux-overhaul/`

**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ui-contracts.md ✓, quickstart.md ✓

**Tests**: Included — FR-017 and FR-018 in spec.md explicitly require all tests to pass on both Android and iOS.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Maps to user story from spec.md (US1–US5)
- Exact file paths included in every description

---

## Phase 1: Setup

**Purpose**: Confirm project baseline before any changes.

- [x] T001 Verify `flutter pub get` completes cleanly and `flutter test` runs (even with the stale counter failure) — baseline check, no code changes

---

## Phase 2: Foundational — Model Immutability

**Purpose**: Make all core models fully immutable. **BLOCKS every subsequent phase** — state layer rewrite (Phase 3) cannot begin until all models expose `copyWith` and have no mutable fields.

- [x] T002 [P] Make `Player.isAlive` and `Player.role` `final` fields in `lib/models/player.dart` — no other changes needed (`copyWith` already correct)
- [x] T002 [P] Make all fields in `NightActionRecord` `final`; add `copyWith` with sentinel-pattern for nullable String fields matching `AbilityState` pattern in `lib/models/night_action_record.dart`
- [x] T002 [P] Make `VoteEntry.voteCount` `final` and add `copyWith({int? voteCount})`; make all `VoteTally` fields `final` and add `copyWith`; rewrite `VoteTally.resolve()` to return a new `VoteTally` instance instead of mutating self — `lib/models/vote_tally.dart`
- [x] T002 Make `GameSession.currentPhaseIndex` and `GameSession.round` `final`; add `GameSession.copyWith(...)` using `List.from()` for all list fields to ensure identity break — `lib/models/game_session.dart`

**Checkpoint**: All models are fully immutable. `flutter analyze` must show 0 errors (direct field mutation sites will now be compile errors — expected, fixed in Phase 3).

---

## Phase 3: User Story 1 — Stable Game Session, No Crashes (Priority: P1) 🎯 MVP

**Goal**: Wolf kills actually happen; night resolution works; no repeated screen pushes; state never has shared mutable references.

**Independent Test**: Start a 7-player game, run 2 full rounds (night + day voting + execution), verify wolf kill victim appears dead at morning and win condition triggers correctly — 0 crashes.

### Implementation for User Story 1

- [x] T002 [US1] Rewrite `GameNotifier` phase/round navigation methods (`nextPhase`, `prevPhase`, `nextRound`) and player status methods (`killPlayer`, `revivePlayer`, `undoLastDeath`, `updateNote`, `startGame`, `endGame`) to use `state!.copyWith(...)` — remove `_clone()` helper entirely — `lib/providers/game_provider.dart`
- [x] T002 [US1] Rewrite `GameNotifier` night-action recording methods (`recordBodyguardProtect`, `recordWitchSave`, `recordWitchKill`, `recordSeer`); add `clearWitchKill()` method; fix `recordWolfKill` to use `_pendingNight = _pendingNight!.copyWith(wolfTarget: id)` pattern — `lib/providers/game_provider.dart`
- [x] T002 [US1] Rewrite `GameNotifier.resolveNight()` fully: use immutable list operations; clear `_pendingNight` only after computing `updatedNight = night.copyWith(resolved: true)`; embed win condition check in final `copyWith` call — `lib/providers/game_provider.dart`
- [x] T002 [US1] Rewrite `GameNotifier` voting methods (`beginDayVote`, `nominatePlayer`, `setVoteCount`, `resolveVote`) and execution methods (`confirmExecution`, `recordHunterShot`) using `copyWith` pattern with embedded win-condition check; remove `checkAndUpdateResult()` method entirely — `lib/providers/game_provider.dart`
- [x] T0XX [US1] Fix screen push loop in `GameMasterScreen`: add `_lastPushedPhaseId` and `_morningResolvedPhaseId` fields; move `NightActionScreen` push, `DayVotingScreen` push, and `resolveNight` call into `_onPhaseChanged()`; remove the two existing `postFrameCallback` blocks from `build()`; remove all `checkAndUpdateResult()` call sites; call `beginNightAction(session.round)` immediately before pushing `NightActionScreen` — `lib/screens/game/game_master_screen.dart`
- [x] T0XX [US1] Fix witch kill deselect bug: replace `NightActionScreen._buildWitchActions` tap handler with toggle logic that calls `ref.read(gameProvider.notifier).clearWitchKill()` when `isSelected` is true (deselecting) — `lib/screens/game/night_action_screen.dart`
- [x] T0XX [P] [US1] Replace stale counter test with app smoke test (`expect(find.text('Ma Sói'), findsOneWidget)`) — `test/widget_test.dart`
- [x] T0XX [P] [US1] Create `test/game_notifier_test.dart` with unit tests for all `GameNotifier` state transitions: `killPlayer` (immutable, no shared references), `resolveNight` (wolf kill, bodyguard block, witch save, witch kill, noop when pending null), `undoLastDeath` (restores player, noop when empty), `confirmExecution` (fool immunity once, hunter shot pending), `setVoteCount` (immutable), `nextRound` (appends phases, detects win) — `test/game_notifier_test.dart`

**Checkpoint**: Run `flutter test` → 0 failures. Run 7-player game manually → wolf kills resolve at morning, no double screen pushes, app survives 2+ rounds.

---

## Phase 4: User Story 2 — Kill/Death Management (Priority: P1)

**Goal**: Killing is explicit and reversible; dead players are visually distinct and unselectable.

**Independent Test**: Mark 3 players dead during a night phase, undo 1 death, verify player list reflects correct state — no game advancement required.

### Implementation for User Story 2

- [x] T0XX [US2] Update `NightActionScreen` FAB: change icon to `Icons.check_circle_outline`; change label to `'Xác nhận'` when `_selectedPlayerId != null` else `'Bỏ qua'`; add wolf-phase guard — if `_roleId == 'werewolf'` and no selection, show `SnackBar('Ma Sói không chọn mục tiêu — đêm nay không ai bị giết bởi Sói')` before popping — `lib/screens/game/night_action_screen.dart`
- [x] T0XX [US2] Add undo last death button: in `GameMasterScreen._buildAppBar()`, add `IconButton(icon: const Icon(Icons.undo_outlined))` visible only when `session.deathHistory.isNotEmpty`; calls `ref.read(gameProvider.notifier).undoLastDeath()` — `lib/screens/game/game_master_screen.dart`

**Checkpoint**: Kill a player, undo the kill → player reappears in alive list. Night screen shows "Bỏ qua" FAB when no player selected for wolf phase.

---

## Phase 5: User Story 3 — Player List Sortable and Filterable (Priority: P2)

**Goal**: QT can sort players by role (wolves first) and filter to alive/dead only.

**Independent Test**: In role assignment screen with 8 mixed-role players, enable "Sort by Role" → verify wolves appear first. In game master screen, enable "Alive only" → dead players disappear instantly.

### Implementation for User Story 3

- [x] T0XX [US3] Add `PlayerSortMode` (`default_`, `byRole`) and `PlayerFilterMode` (`all`, `aliveOnly`, `deadOnly`) enums; add `_sortMode` and `_filterMode` fields to `_GameMasterScreenState`; implement `_filteredSortedPlayers(List<Player> all)` method with role priority map (werewolf=1, bodyguard=2, seer=3, witch=4, hunter=5, fool=6, villager=7, null=8) — `lib/screens/game/game_master_screen.dart`
- [x] T0XX [US3] Add sort/filter toggle row widget above the `_AlivePlayerChips` section in `GameMasterScreen`; pass `_filteredSortedPlayers(session.players)` to both `_PlayerListPanel` and `_AlivePlayerChips` instead of raw `session.players` — `lib/screens/game/game_master_screen.dart`

**Checkpoint**: With a 7-player game in progress, toggling "By Role" reorders the list with wolves at top; toggling "Alive only" hides dead players; switching back to "All" restores them.

---

## Phase 6: User Story 4 — Balanced Team Suggestion (Priority: P2)

**Goal**: Role assignment screen shows recommended preset and auto-distributes with one tap.

**Independent Test**: Open role assignment with 7 players → see preset panel with "2× Ma Sói, 1× Tiên Tri, 1× Phù Thủy, 3× Dân Làng" → tap Auto-Distribute → all 7 players have matching roles within 1 second.

### Implementation for User Story 4

- [x] T0XX [US4] Add `_buildPresetPanel(int playerCount)` method to `RoleAssignmentScreen`: reads `WerewolfPresets.table[playerCount]`; returns `SizedBox.shrink()` when null (< 5 players); displays role chips in a `Wrap` (role emoji + name + `×N`) inside a glass card; includes a full-width `ElevatedButton('Auto-Distribute')` that calls `setupProvider.notifier.autoDistribute()` — `lib/screens/setup/role_assignment_screen.dart`
- [x] T0XX [US4] Update balance indicator in `RoleAssignmentScreen._balanceLabel` row: replace emoji text prefix with `Icon(Icons.balance_outlined, size: 16)` — `lib/screens/setup/role_assignment_screen.dart`

**Checkpoint**: With 7 players on role assignment screen, preset panel shows correct counts. Auto-Distribute assigns all 7 roles. Balance indicator shows green with outlined balance icon.

---

## Phase 7: User Story 5 — Outlined Icons (Priority: P3)

**Goal**: All interactive icon controls use Material outlined icons; no emoji in buttons.

**Independent Test**: On role assignment screen, all tappable icon buttons show Material outlined icons. No emoji characters appear inside `Icon`, `IconButton`, or action chip icon slots.

### Implementation for User Story 5

- [x] T0XX [P] [US5] Replace emoji icons in `DayVotingScreen`: `Icons.add` → `Icons.add_circle_outline`; `Icons.remove` → `Icons.remove_circle_outline`; `Text('👑')` → `const Icon(Icons.emoji_events_outlined, size: 18)`; AppBar title `'Bỏ Phiếu 🗳️'` → `'Bỏ Phiếu'`; button text `'Xác nhận xử tử ⚔️'` → `'Xác nhận xử tử'` — `lib/screens/game/day_voting_screen.dart`
- [x] T0XX [US5] Replace `GameMasterScreen` FAB child `Text('📖')` with `const Icon(Icons.menu_book_outlined)` — `lib/screens/game/game_master_screen.dart`
- [x] T0XX [US5] Replace `_PlayerRow` revive trailing `Icons.favorite` with `Icons.favorite_border` — `lib/screens/game/game_master_screen.dart`

**Checkpoint**: Flutter analyze shows 0 errors. Visually confirm no emoji in button/icon slots on day voting, game master, and player setup screens.

---

## Phase 8: Polish & Integration Testing

**Purpose**: Confirm all acceptance scenarios pass on both Android and iOS per quickstart.md.

- [x] T0XX Run full test suite `flutter test` → confirm 0 failures, 0 errors across all test files
- [x] T0XX [P] Execute 7-player integration test on Android following all 38 steps in `specs/002-werewolf-state-ux-overhaul/quickstart.md` — document any failures
- [x] T0XX [P] Execute 7-player integration test on iOS Simulator following all 38 steps in `specs/002-werewolf-state-ux-overhaul/quickstart.md` — document any failures
- [x] T0XX Execute 8-player integration test on both Android and iOS following the 8-player variant section in `specs/002-werewolf-state-ux-overhaul/quickstart.md`

**Checkpoint**: All 26 checklist rows in `quickstart.md` Test Pass Criteria table show ✓ for both Android and iOS columns.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user story phases**
- **US1 (Phase 3)**: Depends on Phase 2 — BLOCKS US2, US3, US4, US5 (all state layer work)
- **US2 (Phase 4)**: Depends on Phase 3 (night action flow must work before UX polish)
- **US3 (Phase 5)**: Depends on Phase 3 (needs correct player list state); independent of US2
- **US4 (Phase 6)**: Depends on Phase 3 (auto-distribute calls into GameNotifier); independent of US2/US3
- **US5 (Phase 7)**: Depends on Phase 2 only (icon changes are cosmetic, no logic deps); can start after Phase 2
- **Polish (Phase 8)**: Depends on all phases complete

### User Story Dependencies

- **US1 (P1)**: After Foundational — no story dependencies
- **US2 (P1)**: After US1 — needs night action flow correct
- **US3 (P2)**: After US1 — needs stable state; **independent of US2**
- **US4 (P2)**: After US1 — needs GameNotifier stable; **independent of US2, US3**
- **US5 (P3)**: After Foundational — no state logic deps; **independent of US1–US4** (can run concurrently with US1 if desired)

### Within Each Phase

- Models before provider rewrite (T002–T005 before T006–T009)
- Provider rewrite before screen fixes (T006–T009 before T010–T011)
- Screen fixes before UX enhancements (T010–T011 before T014–T022)

### Parallel Opportunities

- T002, T003, T004 — different model files, fully parallel
- T012, T013 — different test files, parallel after T009
- T016, T017 — sequential (same file); T018, T019 — sequential (same file); but T016 ∥ T018 (different files)
- T020 ∥ T021 — different screens; T021, T022 — sequential (same file)
- T023, T024, T025 — parallel (tests + emulator runs)

---

## Parallel Example: Phase 2 (Foundational)

```
Launch simultaneously (different files, no deps):
  T002: lib/models/player.dart — make fields final
  T003: lib/models/night_action_record.dart — make fields final + copyWith
  T004: lib/models/vote_tally.dart — immutable VoteEntry + VoteTally
Then sequentially:
  T005: lib/models/game_session.dart — add copyWith (reads player.dart types)
```

## Parallel Example: Phase 3 (US1)

```
Sequential (same file, serial dependency chain):
  T006 → T007 → T008 → T009: lib/providers/game_provider.dart
  T010: lib/screens/game/game_master_screen.dart

Parallel after T009:
  T011: lib/screens/game/night_action_screen.dart
  T012: test/widget_test.dart
  T013: test/game_notifier_test.dart
```

## Parallel Example: US3 + US4 + US5 (after Phase 3)

```
Launch simultaneously (different files):
  T016 → T017: game_master_screen.dart (sort/filter)
  T018 → T019: role_assignment_screen.dart (preset panel)
  T020: day_voting_screen.dart (icons)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational models (T002–T005)
3. Complete Phase 3: US1 state layer + night flow (T006–T013)
4. Complete Phase 4: US2 kill/undo UX (T014–T015)
5. **STOP and VALIDATE**: Run `flutter test` + 7-player game on Android + iOS
6. If clean: proceed to US3–US5

### Incremental Delivery

1. T001–T005 → models immutable, compile errors surface in provider
2. T006–T013 → core game loop works, wolf kills happen, tests green
3. T014–T015 → kill/undo UX polished
4. T016–T019 → sort/filter + preset (can demo without breaking US1/US2)
5. T020–T022 → icon cleanup (cosmetic, zero risk)
6. T023–T026 → full validation on both platforms

---

## Notes

- [P] tasks operate on different files — safe to run concurrently
- [Story] label maps each task to the user story acceptance criteria in spec.md
- After T005, `flutter analyze` will produce compile errors at all direct-mutation sites — this is expected and will be resolved in T006–T009
- `checkAndUpdateResult()` is removed in T009; all call sites in game_master_screen.dart are cleaned up in T010
- iOS testing (T025, T026) requires Xcode + iOS Simulator — run `flutter devices` to verify simulator is listed
- Each checkpoint is a safe commit point
