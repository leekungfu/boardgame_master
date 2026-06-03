# Tasks: Werewolf QT Automation

**Input**: Design documents from `/specs/001-werewolf-qt-automation/`

**Prerequisites**: plan.md ✓ spec.md ✓ research.md ✓ data-model.md ✓ contracts/ui-contracts.md ✓ quickstart.md ✓

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks grouped by user story + dedicated UI phases for Gen Z visual design.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in this phase)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Exact file paths are included in every task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Install all new dependencies before any code is written.

- [x] T\1 Add `shared_preferences: ^2.3.2` under `dependencies` in `pubspec.yaml`
- [x] T\1 [P] Add `google_fonts: ^6.2.1` under `dependencies` in `pubspec.yaml` (for Cinzel display font + Nunito body font)
- [x] T\1 [P] Add `confetti: ^0.7.0` under `dependencies` in `pubspec.yaml` (for win-screen celebration)
- [x] T\1 Run `flutter pub get` and verify `pubspec.lock` lists all three new packages (depends on T001, T034, T035)

**Checkpoint**: `flutter pub get` exits 0; `dart analyze` reports no errors.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and persistence layer that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T\1 [P] Create `AbilityState` model with `witchSaveUsed`, `witchKillUsed`, `foolImmunityUsed`, `hunterShotPending`, `hunterShotTarget`, `lastBodyguardTarget` fields plus `toJson`/`fromJson` in `lib/models/ability_state.dart`
- [x] T\1 [P] Create `NightActionRecord` model with `round`, `wolfTarget`, `bodyguardTarget`, `witchSaveTarget`, `witchKillTarget`, `seerTarget`, `seerResultIsWolf`, `resolved` fields and `resolveDeaths()` computed getter plus `toJson`/`fromJson` in `lib/models/night_action_record.dart`
- [x] T\1 [P] Create `VoteTally` model with `round`, `nominations` (`List<VoteEntry>`), `resolved`, `executedPlayerId`, `wasTied` fields plus `VoteEntry` class and `toJson`/`fromJson` in `lib/models/vote_tally.dart`
- [x] T\1 [P] Add `scriptText` (String, default empty) and `phaseType` (enum: `nightStep | morning | dayDiscussion | dayVoting | special`) fields to `GamePhase` in `lib/models/game_phase.dart`
- [x] T\1 [P] Create `RolePreset` class and `WerewolfPresets.table` map (player counts 5–20 → balanced role counts per `research.md` preset table) in `lib/games/werewolf/werewolf_presets.dart`
- [x] T\1 Extend `GameSession` to add `abilityState` (`AbilityState`), `nightLog` (`List<NightActionRecord>`), `currentVoteTally` (`VoteTally?`), `deathHistory` (`List<DeathEvent>`) fields; add `DeathEvent` inline class; update constructor, `copyWith`, and `_cloneSession` in `lib/models/game_session.dart` (depends on T003, T004, T005)
- [x] T\1 Create `PersistenceService` with `saveSession(GameSession)` and `restoreSession()` using `shared_preferences` JSON under key `active_game_session` in `lib/providers/persistence_service.dart` (depends on T008)

**Checkpoint**: All models compile; `dart analyze` passes with no errors.

---

## Phase 3: Visual Design Foundation 🎨 (Gen Z UI System)

**Purpose**: Establish the complete visual language before touching any screens. All story phases apply these components — doing this first means every screen looks great from the start.

**⚠️ CRITICAL**: Must complete before any screen-level tasks (Phase 4+).

- [x] T\1 [P] Redesign `AppTheme` — extend color palette with neon glow variants (`accentGlow`, `wolfCrimson`, `seerViolet`, `witchEmerald`, `hunterAmber`); replace static `TextStyle` font families with `GoogleFonts.cinzel()` for display headings and `GoogleFonts.nunito()` for body text; add `glassCardDecoration` helper (`BoxDecoration` with `BackdropFilter`-ready semi-transparent fill + gold glow border) in `lib/theme/app_theme.dart`
- [x] T\1 [P] Create `AppGradients` class with scene gradients (`deepNight`: `#0A0A1A → #1A1A3E`, `crimsonDawn`: `#1A0A0A → #3E1010`, `goldenDay`: `#1C2A1C → #2E3E1C`) and per-role gradients keyed by `roleId` (`werewolf`: crimson/dark-red, `seer`: violet/indigo, `witch`: emerald/dark-green, `bodyguard`: cyan/teal, `hunter`: amber/brown, `fool`: yellow/orange, `villager`: grey/charcoal) in `lib/theme/app_gradients.dart`
- [x] T\1 [P] Create `RoleCardWidget` — large card with per-role `LinearGradient` background from `AppGradients`; role emoji rendered at 48px with a colored `BoxShadow` glow matching the role gradient; role name in `GoogleFonts.cinzel` bold 18px; description in `Nunito` 13px; `compact: bool` variant for list rows (smaller, horizontal layout) in `lib/widgets/role_card_widget.dart`
- [x] T\1 [P] Create `PlayerStatusChip` — rounded-rect chip with player name and seat number; when `isAlive: true`: gold `BoxShadow` ring glow + semi-transparent gold border; when `isAlive: false`: greyscale `ColorFiltered` overlay + `💀` icon overlaid at top-right + strikethrough text in `lib/widgets/player_status_chip.dart`
- [x] T\1 [P] Create `AtmosphericBackground` widget — `isNight: true`: deep `#0A0A1A→#0D0D2E` gradient + star-field overlay drawn with `CustomPainter` (50–70 random-positioned white circles 1–3px, `opacity` 0.3–0.9); `isNight: false`: warm `#1C2A1C→#2A3A1C` gradient + subtle amber glow ellipse at top-right; both variants use `Stack` with the painter on top in `lib/widgets/atmospheric_background.dart`
- [x] T\1 Redesign `HomeScreen` — replace plain `Scaffold` body with `AtmosphericBackground(isNight: true)`; animate title "Board Game\nMaster" with `FadeTransition` + `SlideTransition` from below on first render using `AnimationController`; game cards get `AppTheme.glassCardDecoration` with the accent glow border; add faint 🐺 watermark emoji (opacity 0.04, 200px) as `Positioned` background element in `lib/screens/home_screen.dart` (depends on T036, T037, T040)
- [x] T\1 Redesign `PlayerSetupScreen` — wrap content with `AtmosphericBackground(isNight: true)`; replace `TextField` with a glass-styled input container using `AppTheme.glassCardDecoration`; player rows added via `AnimatedList` with `SizeTransition` entrance; each row uses `PlayerStatusChip` style; player count displayed as glowing badge top-right in `lib/screens/setup/player_setup_screen.dart` (depends on T036, T039, T040)

**Checkpoint**: `HomeScreen` and `PlayerSetupScreen` show the new atmospheric theme; `dart analyze` passes; no existing game logic is broken.

---

## Phase 4: User Story 1 — Auto Role Distribution (Priority: P1) 🎯 MVP

**Goal**: QT taps one button to get a balanced role set; screens are fully styled with the new visual system.

**Independent Test**: Enter 8 players on the new-styled setup screen, tap "Phân vai tự động", verify all 8 players receive preset roles and the role picker shows `RoleCardWidget` visuals with team-color gradients.

- [x] T\1 [P] [US1] Add `autoDistribute(List<Player> players)` method to `WerewolfGame` that reads from `WerewolfPresets.table` by player count and returns the player list with roles assigned; throws `ArgumentError` if count is out of 5–20 range in `lib/games/werewolf/werewolf_game.dart`
- [x] T\1 [P] [US1] Add `autoDistribute()` action to `SetupNotifier` that calls `WerewolfGame.autoDistribute(state.players)` and replaces `state.players` in `lib/providers/game_provider.dart`
- [x] T\1 [US1] Add "Phân vai tự động ⚡" button and team-split balance badge ("🐺×2  🏘×6 — cân bằng") to `RoleAssignmentScreen`; badge text color changes red if unbalanced in `lib/screens/setup/role_assignment_screen.dart` (depends on T010, T011)
- [x] T\1 [US1] Apply `RoleCardWidget` (compact variant) inside the role-picker bottom sheet replacing plain `ListTile`; each card shows the role's gradient background strip; animate role assignment with a brief `ScaleTransition` bounce (1.0→1.12→1.0, 200ms, `Curves.easeOut`) on the player row chip when a role is assigned in `lib/screens/setup/role_assignment_screen.dart` (depends on T038)

**Checkpoint**: Tapping "Phân vai tự động" distributes correct preset; role picker shows gradient role cards; bounce animation fires on assignment.

---

## Phase 5: User Story 2 — Guided Night Phase Script (Priority: P1)

**Goal**: Each night step shows QT the exact narration text inside an atmospheric cinematic screen that feels dramatic and immersive.

**Independent Test**: Start game, advance to night. `NightActionScreen` shows star-field background, role-colored glow script card, 4-step dot indicator. Kill Tiên Tri, start next night — Tiên Tri dot gone.

- [x] T\1 [P] [US2] Enrich `buildRoundPhases()` in `WerewolfGame` — set `scriptText` (Vietnamese narration per research.md script table) and `phaseType = PhaseType.nightStep` on every role night step; set `phaseType = PhaseType.morning` on morning phase in `lib/games/werewolf/werewolf_game.dart`
- [x] T\1 [US2] Create `NightActionScreen` skeleton — script card displaying `phase.scriptText` in `GoogleFonts.cinzel` italic, step title header, role emoji at 64px, "Xong ✓" action button that pops the screen in `lib/screens/game/night_action_screen.dart`
- [x] T\1 [US2] Route `PhaseType.nightStep` → push `NightActionScreen`; add morning announcement inline card for `PhaseType.morning` in `GameMasterScreen` in `lib/screens/game/game_master_screen.dart` (depends on T013, T014)
- [x] T\1 [US2] Style `NightActionScreen` — wrap entire screen with `AtmosphericBackground(isNight: true)`; script card uses `AppTheme.glassCardDecoration` + `BoxShadow` glow in the role's accent color (wolf=crimson, seer=violet, witch=emerald, bodyguard=cyan, villager=gold); step progress shown as a row of 4–5 horizontal dot indicators (filled dot = current, outline = upcoming, checkmark = done) at the top in `lib/screens/game/night_action_screen.dart` (depends on T036, T037, T040)

**Checkpoint**: Night screen is visually distinct and atmospheric; role glow color matches the active role; step dots update correctly.

---

## Phase 6: User Story 3 — Night Action Recording (Priority: P1)

**Goal**: QT records night actions via a styled player picker; dawn announcement uses dramatic visual treatment.

**Independent Test**: Record Ma Sói → A, Phù Thủy save → A. Morning shows "Không có ai chết" with peaceful visual. Record Ma Sói → B, no save. Morning shows B's name in gold with skull in a dawn-colored reveal.

- [x] T\1 [P] [US3] Add night action methods to `GameNotifier`: `beginNightAction`, `recordWolfKill`, `recordBodyguardProtect`, `recordWitchSave`, `recordWitchKill`, `recordSeer`, `resolveNight` in `lib/providers/game_provider.dart` (depends on T008)
- [x] T\1 [US3] Add role-specific player picker to `NightActionScreen` below script card — alive players displayed as `PlayerStatusChip` rows; label changes by role ("Ma Sói chọn giết:", "Hiệp Sĩ bảo vệ:", etc.) in `lib/screens/game/night_action_screen.dart` (depends on T016, T039)
- [x] T\1 [US3] Add morning announcement to `GameMasterScreen` for `PhaseType.morning` — reads `nightLog.last.died`; "nobody died" shows 🌙 icon with soft white glow; "player died" shows player name in `GoogleFonts.cinzel` gold italic + 💀 icon + their role revealed in role-color text in `lib/screens/game/game_master_screen.dart` (depends on T016)
- [x] T\1 [P] [US3] Create `AbilityStatusWidget` — two `Container` pills ("🧪 Bình cứu: còn" in green / "đã dùng" in grey, same for "☠️ Bình độc") reading `AbilityState` from `gameProvider`; pill uses `AppTheme.glassCardDecoration` micro style in `lib/widgets/ability_status_widget.dart` (depends on T036)
- [x] T\1 [US3] Embed `AbilityStatusWidget` in `NightActionScreen` when `activeRoleIds[0] == 'witch'`; disable the relevant picker option (grey overlay + lock icon) when potion is already used in `lib/screens/game/night_action_screen.dart` (depends on T019)
- [x] T\1 [US3] Animate morning announcement reveal — when `PhaseType.morning` is shown, play a `TweenAnimationBuilder<Color>` that transitions the background from `AppGradients.deepNight` to `AppGradients.crimsonDawn` (death) or `AppGradients.goldenDay` (no death) over 1.2s; deceased player row slides in with `SlideTransition` from left in `lib/screens/game/game_master_screen.dart` (depends on T036, T037)

**Checkpoint**: Night recording works end-to-end; morning announcement background color matches the outcome (dawn=death, peaceful=no death); Witch pills lock correctly.

---

## Phase 7: User Story 4 — Day Voting Management (Priority: P2)

**Goal**: Day voting screen is visually engaging with animated vote bars and clear winner highlighting.

**Independent Test**: Open day voting with 6 alive players; nominate A (3 votes) and B (1 vote); verify animated vote bars show proportional fills; A pulses gold. Tie scenario: A=B=2 → tie dialog appears.

- [x] T\1 [P] [US4] Add day voting methods to `GameNotifier`: `beginDayVote`, `nominatePlayer`, `setVoteCount`, `resolveVote`, `confirmExecution` (with Fool immunity check) in `lib/providers/game_provider.dart`
- [x] T\1 [US4] Create `DayVotingScreen` — alive players as tappable nomination chips; each nominated player shown as a card with (+/-) vote stepper; "Xác nhận xử tử" button enabled when winner is clear; tie `AlertDialog` with "Bỏ phiếu lại / Bỏ qua / Chọn ngẫu nhiên" options; Fool immunity `SnackBar` in `lib/screens/game/day_voting_screen.dart` (depends on T021)
- [x] T\1 [US4] Route `PhaseType.dayVoting` → push `DayVotingScreen` from `GameMasterScreen` in `lib/screens/game/game_master_screen.dart` (depends on T022)
- [x] T\1 [US4] Style `DayVotingScreen` — wrap with `AtmosphericBackground(isNight: false)`; each nominated player card uses `AppTheme.glassCardDecoration`; vote count shown as an animated horizontal `LinearProgressIndicator` bar (green fill, width proportional to votes vs total); leading candidate card pulses gold using a looping `AnimationController` border glow (period 1.2s); tie `AlertDialog` uses dark blurred overlay with bold centered `GoogleFonts.cinzel` options in `lib/screens/game/day_voting_screen.dart` (depends on T036, T037, T040)

**Checkpoint**: Vote bars animate when +/- is tapped; leading candidate glows gold; day screen feels distinctly different from night screen.

---

## Phase 8: User Story 5 — Special Ability Tracker (Priority: P2)

**Goal**: Hunter and Fool special moments get dramatic visual treatment that QT cannot miss.

**Independent Test**: Mark Hunter dead → interrupt dialog appears immediately with `AtmosphericBackground` + dramatic heading. Fool vote-executed → full-screen 🤪 reveal banner.

- [x] T\1 [P] [US5] Add `recordHunterShot(targetPlayerId)` to `GameNotifier`; update `resolveNight()` and `confirmExecution()` to detect Hunter death and set `hunterShotPending = true` in `lib/providers/game_provider.dart`
- [x] T\1 [US5] Add Hunter shot interrupt dialog to `GameMasterScreen` — triggered when `abilityState.hunterShotPending`; dialog uses full-height `BottomSheet` (not `AlertDialog`) with dark background, 🏹 hero icon in amber glow, "Thợ Săn vừa chết! Họ được bắn 1 người." heading in `GoogleFonts.cinzel`, alive player chip list for target selection in `lib/screens/game/game_master_screen.dart` (depends on T024, T036, T039)
- [x] T\1 [US5] Add Fool immunity banner to `DayVotingScreen` — shown via `showGeneralDialog` (full-screen dark overlay) with centered 🤪 emoji at 96px, "Thằng Ngốc! Miễn tử lần này." in `GoogleFonts.cinzel` 28px gold, fading in over 400ms; auto-dismisses after 2.5s in `lib/screens/game/day_voting_screen.dart` (depends on T021, T036)

**Checkpoint**: Hunter bottom sheet is visually unmissable; Fool immunity full-screen banner auto-dismisses; both feel like game moments, not alerts.

---

## Phase 9: User Story 6 — QT Reference Card (Priority: P3)

**Goal**: Role reference panel uses the full visual system — each role row shows its gradient identity card so QT can identify roles at a glance.

**Independent Test**: Open reference panel mid-game; all 7 role cards show with correct gradients, Vietnamese descriptions, and live ability status. Dismiss — game state unchanged.

- [x] T\1 [P] [US6] Create `RoleReferencePanel` as `DraggableScrollableSheet` — lists all roles assigned in current game; each row shows role emoji, name in `GoogleFonts.cinzel`, full Vietnamese description, alive/dead status badge, and ability state pills in `lib/screens/game/role_reference_panel.dart`
- [x] T\1 [US6] Add reference `FloatingActionButton` (📖 icon) to `GameMasterScreen` — opens `RoleReferencePanel` via `showModalBottomSheet`; hidden on result screen in `lib/screens/game/game_master_screen.dart` (depends on T027)
- [x] T\1 [US6] Style `RoleReferencePanel` — sheet surface uses `AppTheme.glassCardDecoration` dark glass; each role row uses `RoleCardWidget` compact variant showing the role's team-color gradient strip as a left border; ability state shown as colored `Container` pills (green=available, red/grey=used); drag handle bar styled as a gold pill; sheet slides in with `Curves.easeOutCubic` in `lib/screens/game/role_reference_panel.dart` (depends on T036, T037, T038)

**Checkpoint**: Panel shows gradient role strips; ability state pills reflect real-time game state; slide-in animation is smooth.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Undo support, full persistence, Bodyguard restriction, and Android Studio verification.

- [x] T\1 [P] Add `undoLastDeath()` to `GameNotifier` — pops from `deathHistory`, revives the player, re-checks win condition in `lib/providers/game_provider.dart`
- [x] T\1 [P] Wire persistence — call `PersistenceService.saveSession(state)` at the end of every `GameNotifier` mutation; call `PersistenceService.restoreSession()` in `GameNotifier` constructor in `lib/providers/game_provider.dart` and `lib/providers/persistence_service.dart`
- [x] T\1 Add undo death icon button to `GameMasterScreen` toolbar — visible when `deathHistory.isNotEmpty` and game is not over; calls `undoLastDeath()` in `lib/screens/game/game_master_screen.dart` (depends on T029)
- [x] T\1 [P] Enforce Bodyguard restriction in `NightActionScreen` — when `activeRoleIds[0] == 'bodyguard'`, filter `abilityState.lastBodyguardTarget` from the player picker; filtered player shown greyed with a lock icon in `lib/screens/game/night_action_screen.dart`
- [x] T\1 Verify Android Studio setup per `quickstart.md` — confirm `android/local.properties` paths, create Flutter run configuration targeting `lib/main.dart`, run on emulator/device and confirm app launches without errors

**Checkpoint**: App restores session on cold restart; undo reverts last death; Bodyguard restriction enforced; Android Studio build green.

---

## Phase 11: Animations & Micro-interactions ✨

**Purpose**: Elevate the feel from "functional app" to "cinematic game experience". These tasks add motion and tactile feedback on top of the already-styled screens.

- [x] T\1 [P] Add phase transition animation in `GameMasterScreen` — wrap the phase content area with `AnimatedSwitcher` keyed on `phase.id`; night phases use a dark `FadeTransition`; day phases use a `SlideTransition` from right; background gradient morphs via `TweenAnimationBuilder<Color>` between `deepNight` and `goldenDay` over 800ms in `lib/screens/game/game_master_screen.dart`
- [x] T\1 [P] Add death animation to `PlayerStatusChip` — when `isAlive` transitions `true → false`: run a 600ms `AnimationController` sequence: scale 1.0→0.92 (100ms) + `ColorFiltered` greyscale crossfade (300ms) + skull icon `FadeTransition` in (200ms); use `ValueListenableBuilder` or `StatefulWidget` local controller in `lib/widgets/player_status_chip.dart`
- [x] T\1 Redesign win/result screen — `villagerWin`: add `ConfettiController` (from `confetti` package) that bursts gold + white particles from the top for 3s when the screen mounts; `werewolfWin`: 🐺 emoji uses `ScaleTransition` (0.5→1.2, `Curves.elasticOut`, 700ms) + crimson radial `BoxDecoration` pulse using a looping `AnimationController`; both variants keep the existing role-reveal list below in `lib/screens/game/game_master_screen.dart` (depends on T035)
- [x] T\1 [P] Add `HapticFeedback` micro-interactions throughout — `HapticFeedback.lightImpact()` on phase advance and role assignment; `HapticFeedback.mediumImpact()` on player kill tap and wolf/witch target selection; `HapticFeedback.heavyImpact()` on execution confirm and game-over trigger; add calls in `night_action_screen.dart`, `day_voting_screen.dart`, and `game_master_screen.dart` in `lib/screens/game/`
- [x] T\1 [P] Redesign `CountdownTimer` widget — replace `LinearProgressIndicator` with a circular arc drawn via `CustomPaint` (stroke-style arc that sweeps from full to empty); arc color transitions green→yellow→red as percentage drops below 50%→25%; when ≤5s remaining, add a `ScaleTransition` pulse (1.0→1.06→1.0, period 1.0s) using a looping `AnimationController` in `lib/widgets/countdown_timer.dart`
- [x] T\1 Add `NightActionScreen` script card cinematic entrance — on mount, play a staggered sequence: background fades in (0–300ms), role emoji drops from above with `SlideTransition` + `FadeTransition` (300–500ms), script card slides up from bottom (500–700ms); all driven by a single `AnimationController` with `Interval` curves in `lib/screens/game/night_action_screen.dart`

**Checkpoint**: Phase transitions feel smooth; deaths have a visual "moment"; win screens are satisfying; haptics add tactile confirmation to every key QT action.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user story phases**
- **Phase 3 (Visual Design)**: Depends on Phase 1 — **BLOCKS all screen-level tasks**
- **Phase 4 (US1)**: Depends on Phase 2 + Phase 3
- **Phase 5 (US2)**: Depends on Phase 2 + Phase 3
- **Phase 6 (US3)**: Depends on Phase 5 (extends `NightActionScreen`)
- **Phase 7 (US4)**: Depends on Phase 2 + Phase 3
- **Phase 8 (US5)**: Depends on Phase 7 (extends `confirmExecution` and `DayVotingScreen`)
- **Phase 9 (US6)**: Depends on Phase 2 + Phase 3
- **Phase 10 (Polish)**: Depends on all desired stories complete
- **Phase 11 (Animations)**: Depends on Phase 10

### User Story Dependencies

- **US1 (P1)**: Independent after Phase 2 + Phase 3
- **US2 (P1)**: Independent after Phase 2 + Phase 3
- **US3 (P1)**: Depends on US2 (`NightActionScreen` skeleton)
- **US4 (P2)**: Independent after Phase 2 + Phase 3
- **US5 (P2)**: Depends on US4 (`confirmExecution`, `DayVotingScreen`)
- **US6 (P3)**: Independent after Phase 2 + Phase 3

### Parallel Opportunities Per Story

**Phase 2 + Phase 3 can run concurrently** (different files):
```
Parallel: T003–T007 (models) + T036–T040 (theme/widgets)
Sequential: T008 → T009 (after models)
Sequential: T041 → T042 (after theme + widget deps)
```

**US1** — logic and visual styling:
```
Parallel: T010 (werewolf_game) + T011 (game_provider)
Sequential: T012 (role_assignment_screen) — after T010, T011
Sequential: T043 (styling) — after T012, T038
```

**US2** — logic and visual styling:
```
Parallel: T013 (werewolf_game) + T014 (night_action_screen skeleton)
Sequential: T015 (game_master_screen) — after T013, T014
Sequential: T044 (styling) — after T014, T036, T040
```

**US3** — logic, widgets, and visual:
```
Parallel: T016 (game_provider) + T019 (ability_status_widget)
Sequential: T017, T018, T020 — after T016
Sequential: T045 (dawn animation) — after T018, T036, T037
```

---

## Implementation Strategy

### MVP (US1 + US2 + US3 with full visual polish)

1. Phase 1: Setup (all deps installed)
2. Phase 2: Foundational (models + persistence)
3. Phase 3: Visual Design (theme + shared widgets)
4. Phase 4: US1 (role distribution + styled role picker)
5. Phase 5: US2 (night script + atmospheric screen)
6. Phase 6: US3 (night recording + dawn reveal)
7. **STOP and validate**: Run a full 5-player game end-to-end — night fully guided + visually polished

### Incremental Delivery After MVP

1. Phase 7 (US4): Day voting with animated vote bars
2. Phase 8 (US5): Hunter + Fool dramatic moments
3. Phase 9 (US6): Role reference panel
4. Phase 10 (Polish): Persistence + undo
5. Phase 11 (Animations): Full cinematic micro-interaction pass

---

## Task Count Summary

| Phase | Tasks | Notes |
|-------|-------|-------|
| Phase 1: Setup | 4 | T001, T034, T035, T002 |
| Phase 2: Foundational | 7 | T003–T009 |
| Phase 3: Visual Design | 7 | T036–T042 |
| Phase 4: US1 | 4 | T010–T012, T043 |
| Phase 5: US2 | 4 | T013–T015, T044 |
| Phase 6: US3 | 6 | T016–T020, T045 |
| Phase 7: US4 | 4 | T021–T023, T046 |
| Phase 8: US5 | 3 | T024–T026 |
| Phase 9: US6 | 3 | T027–T028, T047 |
| Phase 10: Polish | 5 | T029–T033 |
| Phase 11: Animations | 6 | T048–T053 |
| **Total** | **53** | 24 parallelizable `[P]` |

---

## Notes

- [P] tasks operate on different files with no shared in-progress dependencies
- Phase 3 (Visual Design) and Phase 2 (Foundational) can run in parallel since they touch different file types — models vs. theme/widgets
- `game_master_screen.dart` accumulates changes across US2, US3, US5, US6, Phase 10, and Phase 11 — keep each addition in clearly separated `build` sub-methods or extract to helper widgets early
- `game_provider.dart` accumulates methods across US1, US3, US4, US5, and Phase 10 — group by concern (night actions / day actions / ability interrupts / persistence)
- All `AnimationController` instances in screens must be created in `initState` and disposed in `dispose` to avoid memory leaks
- `CustomPainter` for star-field (`AtmosphericBackground`) and timer arc (`CountdownTimer`) should mark `shouldRepaint` as `false` for the star-field (static) and `true` for the timer (animating)
