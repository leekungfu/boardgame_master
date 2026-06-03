# Research: Werewolf App — State Fix & UX Overhaul

**Feature**: `002-werewolf-state-ux-overhaul`
**Date**: 2026-05-31

---

## Decisions

### D-001: Root cause of state management bugs

**Decision**: Three distinct categories of bugs exist, all stemming from shared mutable object references.

**Findings**:

**Bug A — Shared list references in `_clone()`**:
`GameNotifier._clone()` passes `s.players`, `s.phases`, `s.nightLog`, `s.deathHistory` directly into the new `GameSession` constructor. The constructor stores these as-is (no copy). Both old and new state share the exact same list objects. Any `.add()` call on one state's list mutates both.

**Bug B — Mutation before clone**:
Every `GameNotifier` method mutates the existing session first (`s.currentPhaseIndex++`, `p.isAlive = false`, `s.nightLog.add(night)`) then calls `_clone(s)`. Since `_clone()` passes the same lists, there is no actual "old state" — only one mutable object that both state versions point at.

**Bug C — `beginNightAction` never called — night kills never resolve**:
`resolveNight()` in `GameNotifier` requires `_pendingNight != null`. However, `beginNightAction()` is never called from any screen before night action screens open. Every `recordWolfKill()`, `recordBodyguardProtect()`, etc. writes to `_pendingNight?.wolfTarget` (null-safe, so no crash, but no-op). `resolveNight()` itself is also never called from the UI — `GameMasterScreen` only calls `nextPhase()` after a night screen pops. Therefore: **wolf kills never happen in the current implementation**.

**Bug D — Repeated screen push loop**:
`GameMasterScreen.build()` unconditionally adds a `postFrameCallback` to push `NightActionScreen` whenever the current phase is a night step. Any state change while the night screen is open (e.g., witch records save → state update) causes `GameMasterScreen` to rebuild and schedule another push. This creates duplicate screen pushes and broken navigation stacks.

**Bug E — Witch kill deselect doesn't clear `_pendingNight`**:
`NightActionScreen._buildWitchActions` only calls `recordWitchKill(p.id)` when `!isSelected`. Deselecting doesn't clear `_pendingNight.witchKillTarget`. If a user selects player A (kill recorded for A) then taps A again to deselect, the kill is still registered.

**Rationale**: All five bugs are fixable without changing the Riverpod architecture — the fix is strict immutability + correct call sequencing.

**Alternatives considered**: Migrating to `Notifier<T>` (Riverpod v2 syntax) — deferred as it would expand scope without adding correctness.

---

### D-002: Immutability pattern

**Decision**: Clone-first, then build new state from immutable transformations.

**Pattern**:
```
void killPlayer(String playerId) {
  final s = state;
  if (s == null) return;
  state = s.copyWith(
    players: s.players
        .map((p) => p.id == playerId ? p.copyWith(isAlive: false) : p)
        .toList(),
    deathHistory: [
      ...s.deathHistory,
      DeathEvent(playerId: playerId, round: s.round, cause: DeathCause.wolfKill),
    ],
  );
  _save();
}
```

**Why**: `copyWith` on every model produces a new instance with new list references. Riverpod's `StateNotifier` performs identity comparison — a new object is always detected as changed, triggering rebuilds. No shared mutable state.

**Models needing `copyWith`**:
- `Player` — already has `copyWith`, but must stop direct mutation (`p.isAlive = false`)
- `GameSession` — needs `copyWith` added (currently has none)
- `NightActionRecord` — all fields must become `final`; needs `copyWith`
- `VoteEntry` — `voteCount` must become `final`; needs `copyWith`
- `VoteTally` — `resolved`, `executedPlayerId`, `wasTied` must become `final`; needs `copyWith` and immutable `resolve()` that returns a new `VoteTally`

---

### D-003: Night action flow redesign

**Decision**: `beginNightAction(round)` must be called by `GameMasterScreen` before pushing `NightActionScreen`. After all night steps complete, the morning phase triggers `resolveNight()`. Screen push must be gated by phase ID to prevent loops.

**Correct flow**:
1. Phase transitions to a night step → `_onPhaseChanged` detects new phase ID → calls `beginNightAction(round)` if not already begun for this round → pushes `NightActionScreen`
2. Each night step screen pops → `nextPhase()` called
3. Phase transitions to morning (`PhaseType.morning`) → `resolveNight(game)` called automatically → deaths computed and applied to state
4. `_AlivePlayerChips` on morning screen shows who died

**Why gated by phase ID**: `_onPhaseChanged` already tracks `_lastPhaseId`. Night screen pushes should be added there (not in `build()`) to ensure they only trigger once per unique phase.

---

### D-004: Sort order for role grouping

**Decision**: Sort priority: Werewolf (1) → Bodyguard (2) → Seer (3) → Witch (4) → Hunter (5) → Fool (6) → Villager (7) → Unassigned (8).

**Rationale**: Wolves first because QT needs to track them most critically. Special villager roles next in night-action order. Plain villagers last. Grouping by team then by night order matches the QT's mental model during play.

---

### D-005: Icon replacement scope

**Decision**: Replace emoji in all `Icon`/`IconButton` widget children and `ActionChip.avatar` text emojis used as functional indicators. Retain role emojis in `Text` widgets that display role identity (role cards, script text, chip labels for player names).

**Specific replacements**:
- `Icons.close` → `Icons.close` (already correct — keep)
- `Icons.favorite` (revive) → `Icons.favorite_border`
- `Text('📖')` (FAB) → `Icon(Icons.menu_book_outlined)`
- `Text('👑')` (vote leader) → `Icon(Icons.emoji_events_outlined)`
- `Text('✓')` in buttons → `Icon(Icons.check_circle_outline)`
- `Icons.add` / `Icons.remove` in vote screen → `Icons.add_circle_outline` / `Icons.remove_circle_outline`
- `Text('🗳️')` in AppBar title → plain text "Bỏ Phiếu"
- `Text('⚔️')` in button → remove from string; use icon separately if needed

---

### D-006: iOS testing parity

**Decision**: Every test (unit, widget, integration) executes identically on both Android and iOS simulators. No platform-conditional test skips.

**Implementation**: `flutter test` runs on the host (platform-agnostic Dart VM). Widget tests exercise the Flutter widget tree. Manual integration testing is performed on iOS Simulator (Xcode) and Android Emulator with an identical 7-player and 8-player game scenario script. The test script is documented in `quickstart.md`.

---

## Resolved Clarifications

All five bugs and all feature gaps are fully understood from codebase analysis — no external research was needed. All `NEEDS CLARIFICATION` items from spec are resolved above.
