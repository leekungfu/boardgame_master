# Implementation Plan: Werewolf App — State Fix & UX Overhaul

**Branch**: `002-werewolf-state-ux-overhaul` | **Date**: 2026-05-31 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-werewolf-state-ux-overhaul/spec.md`

---

## Summary

Fix five root-cause bugs (shared mutable state, missing `beginNightAction` call, night kills never resolving, repeated screen push loop, witch kill deselect not clearing target), then add three UX features (sort/filter player list, preset recommendation panel, icon replacement). Full test coverage on both Android and iOS — no cases skipped on either platform.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (SDK `>=3.0.0 <4.0.0`)

**Primary Dependencies**:
- `flutter_riverpod: ^2.5.1` — state management (existing)
- `uuid: ^4.4.0` — player IDs (existing)
- `shared_preferences: ^2.3.2` — persistence (existing)
- `google_fonts: ^6.2.1` — typography (existing)
- `confetti: ^0.7.0` — win animation (existing)

No new packages required.

**Storage**: `SharedPreferences` JSON persistence (existing, no schema changes).

**Testing**: `flutter_test` (existing); new file `test/game_notifier_test.dart` added.

**Target Platforms**: Android (AVD API 30+) + iOS (Simulator iOS 16+). All tests and integration scenarios run on both.

**Project Type**: Single Flutter mobile app — offline, single-device, portrait only.

**Performance Goals**: All state transitions within one frame (16ms); sort/filter <100ms for ≤20 players.

**Constraints**: Offline, no backend, no new packages.

**Scale/Scope**: 5–20 players; 7 roles; ~10 files changed; 1 new test file.

---

## Constitution Check

Constitution file is a blank template — no project-specific gates are defined. No violations to track.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-werewolf-state-ux-overhaul/
├── plan.md              ← this file
├── spec.md              ← feature spec
├── research.md          ← Phase 0 output (bug analysis, decisions)
├── data-model.md        ← Phase 1 output (model changes, state design)
├── quickstart.md        ← Phase 1 output (run + test instructions)
├── contracts/
│   └── ui-contracts.md  ← Phase 1 output (UI behavior contracts)
├── checklists/
│   └── requirements.md  ← spec quality checklist (all pass)
└── tasks.md             ← Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code — Files Changed

```text
lib/
├── models/
│   ├── player.dart                    CHANGE: make isAlive + role final
│   ├── night_action_record.dart       CHANGE: all fields final; add copyWith
│   ├── vote_tally.dart                CHANGE: VoteEntry + VoteTally fully immutable; resolve() returns new instance
│   └── game_session.dart              CHANGE: add copyWith
├── providers/
│   └── game_provider.dart             CHANGE: rewrite all mutation methods; remove _clone; fix night action flow;
│                                              add clearWitchKill(); embed win check in all kill methods
└── screens/
    ├── setup/
    │   └── role_assignment_screen.dart CHANGE: add preset panel; update balance indicator icon
    └── game/
        ├── game_master_screen.dart     CHANGE: fix push loop; call beginNightAction/resolveNight correctly;
        │                                       add sort/filter controls; add undo button; fix FAB icon
        ├── night_action_screen.dart    CHANGE: fix witch kill deselect; update FAB icon/label
        └── day_voting_screen.dart      CHANGE: replace emoji icons with outlined Material icons

test/
├── widget_test.dart                   CHANGE: replace stale counter test with app smoke test
└── game_notifier_test.dart            NEW: unit tests for all GameNotifier state transitions
```

---

## Implementation Sequence

Features are ordered strictly by dependency. Each group must complete before the next starts.

### Group 1 — Model Immutability (no UI dependencies)

All changes here are pure Dart; no widget changes needed.

**1. `lib/models/player.dart`**
- Change `bool isAlive` → `final bool isAlive`
- Change `Role? role` → `final Role? role`
- `copyWith` already exists — no change needed there
- Verify `Player(id, name)` default constructor still works (isAlive defaults to true)

**2. `lib/models/night_action_record.dart`**
- Change all nullable String fields + `resolved` to `final`
- Add `copyWith({String? wolfTarget, String? bodyguardTarget, String? witchSaveTarget, String? witchKillTarget, String? seerTarget, bool? seerResultIsWolf, bool? resolved})` with sentinel pattern for nullable fields (same pattern as `AbilityState`)
- `resolveDeaths()` remains as a pure function — keep as-is
- `toJson`/`fromJson` unchanged

**3. `lib/models/vote_tally.dart`**
- `VoteEntry`: change `int voteCount` → `final int voteCount`; add `copyWith({int? voteCount})`
- `VoteTally`: change `resolved`, `executedPlayerId`, `wasTied`, `nominations` to `final`; add `copyWith`
- Rewrite `VoteTally.resolve()` to return a new `VoteTally` instance (not void/mutating)
- `toJson`/`fromJson` field names unchanged — no format change

**4. `lib/models/game_session.dart`**
- Make `currentPhaseIndex` and `round` `final` (currently non-final, enabling direct mutation)
- Add `copyWith({List<Player>? players, List<GamePhase>? phases, int? currentPhaseIndex, int? round, GameResult? result, String? qtNote, AbilityState? abilityState, List<NightActionRecord>? nightLog, VoteTally? currentVoteTally, List<DeathEvent>? deathHistory})`
- Use `List.from(this.x)` for list defaults in `copyWith` to ensure list identity breaks
- `toJson` unchanged

---

### Group 2 — State Layer Rewrite

**5. `lib/providers/game_provider.dart` — full rewrite of all GameNotifier methods**

Remove `_clone()` entirely. Rewrite every mutation method to use `state!.copyWith(...)`.

Critical rewrites:

```dart
void killPlayer(String playerId) {
  final s = state; if (s == null) return;
  final updated = s.players.map((p) =>
      p.id == playerId ? p.copyWith(isAlive: false) : p).toList();
  final game = GameRegistry.getById(s.gameId);
  final result = game?.checkWinCondition(updated) ?? s.result;
  state = s.copyWith(players: updated, result: result);
  _save();
}

void revivePlayer(String playerId) {
  final s = state; if (s == null) return;
  state = s.copyWith(
    players: s.players.map((p) =>
        p.id == playerId ? p.copyWith(isAlive: true) : p).toList(),
    result: GameResult.ongoing,
  );
  _save();
}

void undoLastDeath() {
  final s = state;
  if (s == null || s.deathHistory.isEmpty) return;
  final last = s.deathHistory.last;
  state = s.copyWith(
    players: s.players.map((p) =>
        p.id == last.playerId ? p.copyWith(isAlive: true) : p).toList(),
    deathHistory: s.deathHistory.sublist(0, s.deathHistory.length - 1),
    result: GameResult.ongoing,
  );
  _save();
}

void nextPhase() {
  final s = state; if (s == null || !s.hasNextPhase) return;
  state = s.copyWith(currentPhaseIndex: s.currentPhaseIndex + 1);
  _save();
}

void prevPhase() {
  final s = state; if (s == null || s.currentPhaseIndex <= 0) return;
  state = s.copyWith(currentPhaseIndex: s.currentPhaseIndex - 1);
  _save();
}

void nextRound(BaseGame game) {
  final s = state; if (s == null) return;
  final result = game.checkWinCondition(s.players);
  if (result != GameResult.ongoing) {
    state = s.copyWith(result: result); _save(); return;
  }
  final newRound = s.round + 1;
  final newPhases = [...s.phases, ...game.buildRoundPhases(newRound, s.alivePlayers)];
  state = s.copyWith(
    round: newRound,
    phases: newPhases,
    currentPhaseIndex: s.currentPhaseIndex + 1,
  );
  _save();
}

void beginNightAction(int round) {
  _pendingNight = NightActionRecord(round: round);
}

void recordWolfKill(String playerId) {
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(wolfTarget: playerId);
}

void recordBodyguardProtect(String playerId) {
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(bodyguardTarget: playerId);
  final s = state; if (s == null) return;
  state = s.copyWith(abilityState: s.abilityState.copyWith(lastBodyguardTarget: playerId));
}

void recordWitchSave(String playerId) {
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(witchSaveTarget: playerId);
  final s = state; if (s == null) return;
  state = s.copyWith(abilityState: s.abilityState.copyWith(witchSaveUsed: true));
}

void recordWitchKill(String playerId) {
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(witchKillTarget: playerId);
  final s = state; if (s == null) return;
  state = s.copyWith(abilityState: s.abilityState.copyWith(witchKillUsed: true));
}

void clearWitchKill() {  // NEW
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(witchKillTarget: null);
}

void recordSeer(String playerId, bool isWolf) {
  if (_pendingNight == null) return;
  _pendingNight = _pendingNight!.copyWith(seerTarget: playerId, seerResultIsWolf: isWolf);
}

void resolveNight(BaseGame game) {
  final s = state; final night = _pendingNight;
  if (s == null || night == null) return;
  _pendingNight = null;

  final updatedNight = night.copyWith(resolved: true);
  final died = night.resolveDeaths();

  var players = s.players.toList();
  var deathHistory = s.deathHistory.toList();
  var abilityState = s.abilityState;
  var hunterPending = false;

  for (final id in died) {
    players = players.map((p) => p.id == id ? p.copyWith(isAlive: false) : p).toList();
    final cause = night.witchKillTarget == id ? DeathCause.witchPoison : DeathCause.wolfKill;
    deathHistory = [...deathHistory, DeathEvent(playerId: id, round: s.round, cause: cause)];
    final dead = players.firstWhere((p) => p.id == id);
    if (dead.role?.id == 'hunter') hunterPending = true;
  }
  if (hunterPending) abilityState = abilityState.copyWith(hunterShotPending: true);

  state = s.copyWith(
    players: players,
    nightLog: [...s.nightLog, updatedNight],
    deathHistory: deathHistory,
    abilityState: abilityState,
    result: game.checkWinCondition(players),
  );
  _save();
}

void recordHunterShot(String targetPlayerId, BaseGame game) {
  final s = state; if (s == null) return;
  final players = s.players.map((p) =>
      p.id == targetPlayerId ? p.copyWith(isAlive: false) : p).toList();
  state = s.copyWith(
    players: players,
    deathHistory: [...s.deathHistory,
        DeathEvent(playerId: targetPlayerId, round: s.round, cause: DeathCause.hunterShot)],
    abilityState: s.abilityState.copyWith(
        hunterShotPending: false, hunterShotTarget: targetPlayerId),
    result: game.checkWinCondition(players),
  );
  _save();
}

void setVoteCount(String playerId, int count) {
  final s = state; if (s?.currentVoteTally == null) return;
  final tally = s!.currentVoteTally!;
  state = s.copyWith(currentVoteTally: tally.copyWith(
    nominations: tally.nominations
        .map((e) => e.playerId == playerId ? e.copyWith(voteCount: count) : e)
        .toList(),
  ));
}

void resolveVote() {
  final s = state; if (s?.currentVoteTally == null) return;
  state = s!.copyWith(currentVoteTally: s.currentVoteTally!.resolve());
}

void confirmExecution(String playerId, BaseGame game) {
  final s = state; if (s == null) return;
  final target = s.players.firstWhere((p) => p.id == playerId);
  if (target.role?.id == 'fool' && !s.abilityState.foolImmunityUsed) {
    state = s.copyWith(abilityState: s.abilityState.copyWith(foolImmunityUsed: true));
    _save(); return;
  }
  var players = s.players.map((p) =>
      p.id == playerId ? p.copyWith(isAlive: false) : p).toList();
  var abilityState = s.abilityState;
  if (target.role?.id == 'hunter') abilityState = abilityState.copyWith(hunterShotPending: true);
  state = s.copyWith(
    players: players,
    deathHistory: [...s.deathHistory,
        DeathEvent(playerId: playerId, round: s.round, cause: DeathCause.execution)],
    abilityState: abilityState,
    result: game.checkWinCondition(players),
  );
  _save();
}
```

Remove `checkAndUpdateResult()` — win check is now embedded in every kill method.

---

### Group 3 — Screen Fixes

**6. `lib/screens/game/game_master_screen.dart`**

**a) Fix push loop — gate by phase ID in `_onPhaseChanged`:**
- Add `String? _lastPushedPhaseId` and `String? _morningResolvedPhaseId` to state
- Move `NightActionScreen` push + `DayVotingScreen` push into `_onPhaseChanged`
- Call `beginNightAction(round)` before pushing `NightActionScreen`
- Call `resolveNight(game)` when entering morning phase (gate by `_morningResolvedPhaseId`)
- Remove the two existing `postFrameCallback` blocks from `build()`

**b) Add sort/filter:**
- Add `PlayerSortMode _sortMode` and `PlayerFilterMode _filterMode` enum fields to widget state
- Add `List<Player> _filteredSortedPlayers(List<Player> all)` method
- Add sort/filter toggle row above `_AlivePlayerChips` and `_PlayerListPanel`
- Pass computed list to both widgets (not raw `session.players`)

**c) Add undo button:**
- In `_buildAppBar`: add `IconButton(icon: const Icon(Icons.undo_outlined))` when `session.deathHistory.isNotEmpty`
- Calls `ref.read(gameProvider.notifier).undoLastDeath()`

**d) FAB icon fix:** `child: const Icon(Icons.menu_book_outlined)` (remove `Text('📖')`)

**7. `lib/screens/game/night_action_screen.dart`**

**a) Witch kill deselect fix:** Replace `onTap` in witch kill player list to call `clearWitchKill()` on deselect.

**b) FAB update:**
- `icon: const Icon(Icons.check_circle_outline)`
- `label: Text(_selectedPlayerId != null ? 'Xác nhận' : 'Bỏ qua', ...)`

**c) No wolf target warning:** `SnackBar` if wolf phase and no selection.

---

### Group 4 — UI Enhancements

**8. `lib/screens/setup/role_assignment_screen.dart`**
- Add `_buildPresetPanel(int playerCount)` widget
- Reads `WerewolfPresets.table[playerCount]`; returns `SizedBox.shrink()` if null
- Shows role chips with count (e.g., "🐺 Ma Sói ×2") in a `Wrap`
- Auto-Distribute `ElevatedButton` at bottom of panel
- Balance indicator: `Icon(Icons.balance_outlined)` prefix instead of emoji text

**9. `lib/screens/game/day_voting_screen.dart`**
- `Icons.add` → `Icons.add_circle_outline`
- `Icons.remove` → `Icons.remove_circle_outline`
- `Text('👑')` → `const Icon(Icons.emoji_events_outlined, size: 18)`
- AppBar title: `'Bỏ Phiếu'`
- Button text: `'Xác nhận xử tử'` (remove `⚔️`)

---

### Group 5 — Tests

**10. `test/game_notifier_test.dart` (NEW)**

Test groups:
- `killPlayer` — marks player dead; new state has no shared list reference with old state
- `resolveNight` — wolf kills, bodyguard blocks, witch save, witch kill, noop when pending null
- `undoLastDeath` — restores player; noop when history empty
- `confirmExecution` — fool immunity once; hunter shot pending after hunter execution
- `setVoteCount` — updates immutably
- `nextRound` — appends phases; detects win before advancing

**11. `test/widget_test.dart`**
Replace the stale counter test with:
```dart
testWidgets('app starts on home screen', (tester) async {
  await tester.pumpWidget(const BoardGameMasterApp());
  await tester.pump();
  expect(find.text('Ma Sói'), findsOneWidget);
});
```

---

## Complexity Tracking

No constitution violations. No complexity tracking required.

**Critical path**: Group 1 → Group 2 → Group 3 → Group 4 → Group 5.
Groups 4 and 5 are independent of each other once Group 3 is complete.
