# Data Model: Werewolf App — State Fix & UX Overhaul

**Feature**: `002-werewolf-state-ux-overhaul`
**Date**: 2026-05-31

---

## Model Changes

### Player (`lib/models/player.dart`)

**Current problem**: `isAlive` and `role` are non-final mutable fields. Direct mutation (`p.isAlive = false`) is used throughout `GameNotifier`.

**Change**: Make all fields `final`. No structural change to `copyWith` (already correct).

```dart
class Player {
  final String id;
  final String name;
  final bool isAlive;   // was: bool isAlive (non-final)
  final Role? role;     // was: Role? role (non-final)
  ...
}
```

**Impact**: Every mutation in `GameNotifier` that was `p.isAlive = false` must become `.map((p) => p.id == id ? p.copyWith(isAlive: false) : p).toList()`.

---

### NightActionRecord (`lib/models/night_action_record.dart`)

**Current problem**: All nullable String fields and `resolved` are mutable. `_pendingNight` is mutated in-place after being added to `nightLog`.

**Change**: Make all fields `final`. Add `copyWith`. Remove the current pattern of setting `.wolfTarget = x` in favor of constructing a new record.

```dart
class NightActionRecord {
  final int round;
  final String? wolfTarget;
  final String? bodyguardTarget;
  final String? witchSaveTarget;
  final String? witchKillTarget;
  final String? seerTarget;
  final bool? seerResultIsWolf;
  final bool resolved;

  const NightActionRecord({
    required this.round,
    this.wolfTarget,
    this.bodyguardTarget,
    this.witchSaveTarget,
    this.witchKillTarget,
    this.seerTarget,
    this.seerResultIsWolf,
    this.resolved = false,
  });

  NightActionRecord copyWith({
    String? wolfTarget,
    String? bodyguardTarget,
    String? witchSaveTarget,
    String? witchKillTarget,
    String? seerTarget,
    bool? seerResultIsWolf,
    bool? resolved,
  }) { ... }
}
```

**Impact**: `GameNotifier` holds `NightActionRecord? _pendingNight` and replaces it atomically: `_pendingNight = _pendingNight!.copyWith(wolfTarget: playerId)`.

---

### VoteEntry (`lib/models/vote_tally.dart`)

**Current problem**: `voteCount` is mutable; `setVoteCount` directly assigns `entry.voteCount = count`.

**Change**: Make `voteCount` final. Add `copyWith`.

```dart
class VoteEntry {
  final String playerId;
  final int voteCount;

  const VoteEntry({required this.playerId, this.voteCount = 0});

  VoteEntry copyWith({int? voteCount}) =>
      VoteEntry(playerId: playerId, voteCount: voteCount ?? this.voteCount);
}
```

---

### VoteTally (`lib/models/vote_tally.dart`)

**Current problem**: `resolved`, `executedPlayerId`, `wasTied` are mutable. `resolve()` mutates in place.

**Change**: All fields final. `resolve()` returns a new `VoteTally` instead of mutating.

```dart
class VoteTally {
  final int round;
  final List<VoteEntry> nominations;
  final bool resolved;
  final String? executedPlayerId;
  final bool wasTied;

  const VoteTally({
    required this.round,
    this.nominations = const [],
    this.resolved = false,
    this.executedPlayerId,
    this.wasTied = false,
  });

  VoteTally copyWith({
    List<VoteEntry>? nominations,
    bool? resolved,
    String? executedPlayerId,
    bool? wasTied,
  }) { ... }

  VoteTally resolve() {
    // Returns a new VoteTally with resolved=true, executedPlayerId/wasTied computed
  }
}
```

---

### GameSession (`lib/models/game_session.dart`)

**Current problem**: No `copyWith`. `_clone()` in `GameNotifier` passes same list references.

**Change**: Add `copyWith`. All list fields use `List<T>` (not typed as `final` in the class since the constructor already handles them).

```dart
class GameSession {
  // All fields already final or treated as such
  // Add:
  GameSession copyWith({
    List<Player>? players,
    List<GamePhase>? phases,
    int? currentPhaseIndex,
    int? round,
    GameResult? result,
    String? qtNote,
    AbilityState? abilityState,
    List<NightActionRecord>? nightLog,
    VoteTally? currentVoteTally,
    List<DeathEvent>? deathHistory,
  }) => GameSession(
    gameId: gameId,
    players: players ?? List.from(this.players),
    phases: phases ?? List.from(this.phases),
    currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
    round: round ?? this.round,
    result: result ?? this.result,
    qtNote: qtNote ?? this.qtNote,
    abilityState: abilityState ?? this.abilityState,
    nightLog: nightLog ?? List.from(this.nightLog),
    currentVoteTally: currentVoteTally ?? this.currentVoteTally,
    deathHistory: deathHistory ?? List.from(this.deathHistory),
  );
}
```

**Impact**: `GameNotifier._clone()` is replaced entirely by `state = state!.copyWith(...)` calls with explicit new list construction everywhere.

---

## New State: Sort/Filter in GameMasterScreen

**Location**: `_GameMasterScreenState` (local widget state, not in `GameNotifier`).

```dart
enum PlayerSortMode { default_, byRole }
enum PlayerFilterMode { all, aliveOnly, deadOnly }

// In _GameMasterScreenState:
PlayerSortMode _sortMode = PlayerSortMode.default_;
PlayerFilterMode _filterMode = PlayerFilterMode.all;
```

**Sort priority** (for `byRole` mode):
| Priority | Role ID        |
|----------|----------------|
| 1        | `werewolf`     |
| 2        | `bodyguard`    |
| 3        | `seer`         |
| 4        | `witch`        |
| 5        | `hunter`       |
| 6        | `fool`         |
| 7        | `villager`     |
| 8        | null/unassigned|

**Computed list** (used by both `_PlayerListPanel` and `_AlivePlayerChips`):
```dart
List<Player> _filteredSortedPlayers(List<Player> all) {
  final filtered = switch (_filterMode) {
    PlayerFilterMode.all => all,
    PlayerFilterMode.aliveOnly => all.where((p) => p.isAlive).toList(),
    PlayerFilterMode.deadOnly => all.where((p) => !p.isAlive).toList(),
  };
  if (_sortMode == PlayerSortMode.byRole) {
    filtered.sort((a, b) => _rolePriority(a.role?.id) - _rolePriority(b.role?.id));
  }
  return filtered;
}
```

---

## New State: Night Action Tracking

**Location**: `GameNotifier` (replace mutable `_pendingNight` pattern).

```dart
// _pendingNight stays as NightActionRecord? but:
// - beginNightAction creates a fresh immutable record
// - each record* method replaces _pendingNight with copyWith result
// - resolveNight uses _pendingNight, adds to session nightLog, clears _pendingNight
```

**Night phase ID tracking** (to prevent push loops):

```dart
// In _GameMasterScreenState:
String? _lastPushedPhaseId;
```

Push to `NightActionScreen` only when `phase.id != _lastPushedPhaseId`. Set `_lastPushedPhaseId = phase.id` immediately before pushing.

---

## Key Entities — No New Tables / Storage Changes

All changes are in-memory model shape only. `toJson`/`fromJson` round-trip is already correct for the new field signatures since the field names don't change. The `PersistenceService` requires no changes.

---

## State Transitions (corrected flow)

```
[Setup complete] 
  → startGame(session) → GameSession state created with intro phases

[Intro phase] 
  → nextPhase() → advances to round 1 first phase

[Night step phase (activeRoleIds non-empty)]
  → _onPhaseChanged detects new phase
  → beginNightAction(round) called
  → NightActionScreen pushed
  → User records action → record* called → _pendingNight updated via copyWith
  → User taps Done → NightActionScreen popped
  → nextPhase() called from .then() callback

[Morning phase (PhaseType.morning)]
  → resolveNight(game) called
  → Deaths computed from _pendingNight.resolveDeaths()
  → state updated: players dead, deathHistory extended, abilityState updated
  → _pendingNight cleared
  → win condition checked

[Day voting phase]
  → DayVotingScreen pushed
  → beginDayVote() called (inside screen init)
  → Nominations and votes recorded via nominatePlayer/setVoteCount
  → confirmExecution called → player killed
  → Screen popped → checkAndUpdateResult + nextPhase called

[Win condition met (any phase)]
  → state.result updated → GameMasterScreen shows result screen
```
