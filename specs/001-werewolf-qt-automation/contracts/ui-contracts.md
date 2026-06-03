# UI Contracts: Werewolf QT Automation

**Phase 1 output** | **Date**: 2026-05-31

This document defines the navigation contract (screen transitions) and provider state contracts that all screens must respect. It is the single source of truth for how screens communicate.

---

## Navigation Contract

```
HomeScreen
  → [tap game card] → PlayerSetupScreen

PlayerSetupScreen
  → [tap "Tiếp theo"] → RoleAssignmentScreen

RoleAssignmentScreen
  → [tap "Auto-distribute"] → stays on screen (state update only)
  → [tap "🎮 Bắt đầu Game" (all assigned)] → GameMasterScreen (pushAndRemoveUntil → isFirst)

GameMasterScreen
  → [phase.phaseType == nightStep] → NightActionScreen (push)
  → [phase.phaseType == dayVoting] → DayVotingScreen (push)
  → [abilityState.hunterShotPending] → inline Hunter prompt (dialog)
  → [tap FAB reference] → RoleReferencePanel (showModalBottomSheet)
  → [tap home icon + confirm] → HomeScreen (popUntil isFirst + endGame)
  → [session.isGameOver] → ResultScreen (inline, same Scaffold)

NightActionScreen
  → [tap "Xong" on last step] → pop → GameMasterScreen

DayVotingScreen
  → [tap "Xác nhận xử tử"] → pop → GameMasterScreen
  → [tap "Không xử tử"] → pop → GameMasterScreen

RoleReferencePanel
  → [tap close / drag down] → dismiss (no navigation change)
```

---

## Provider State Contract

### `setupProvider` (SetupState)

Consumers: `PlayerSetupScreen`, `RoleAssignmentScreen`

| Field | Type | Invariant |
|-------|------|-----------|
| `selectedGame` | `BaseGame?` | Non-null by time `RoleAssignmentScreen` is shown |
| `players` | `List<Player>` | All players have unique IDs; names trimmed, non-empty |

Mutations allowed in `RoleAssignmentScreen`:
- `assignRole(playerId, role)` — set role for one player
- `clearRoles()` — reset all roles to null
- `autoDistribute()` — NEW: assign balanced preset roles (delegates to `WerewolfGame.autoDistribute`) |

Game can only start when `players.every((p) => p.role != null)`.

---

### `gameProvider` (GameSession?)

Consumers: `GameMasterScreen`, `NightActionScreen`, `DayVotingScreen`, `RoleReferencePanel`

**Invariants**:
- `state == null` → no active game (HomeScreen is correct destination)
- `state != null && !state.isGameOver` → game in progress
- `state != null && state.isGameOver` → result screen

**New mutations** (added to `GameNotifier`):

| Method | Precondition | Effect |
|--------|-------------|--------|
| `beginNightAction(round)` | `state != null` | Creates `NightActionRecord(round)`, stores as `_pendingNight` |
| `recordWolfKill(playerId)` | `_pendingNight != null` | Sets `wolfTarget` |
| `recordBodyguardProtect(playerId)` | `_pendingNight != null` | Sets `bodyguardTarget`; updates `abilityState.lastBodyguardTarget` |
| `recordWitchSave(playerId)` | `!abilityState.witchSaveUsed` | Sets `witchSaveTarget`; sets `witchSaveUsed = true` |
| `recordWitchKill(playerId)` | `!abilityState.witchKillUsed` | Sets `witchKillTarget`; sets `witchKillUsed = true` |
| `recordSeer(playerId, isWolf)` | `_pendingNight != null` | Sets `seerTarget` + `seerResultIsWolf` |
| `resolveNight()` | `_pendingNight != null` | Computes `died`, marks players dead, appends to `nightLog`, triggers Hunter if needed |
| `recordHunterShot(playerId)` | `abilityState.hunterShotPending` | Kills target; clears `hunterShotPending`; `checkAndUpdateResult` |
| `beginDayVote()` | `state != null` | Creates `VoteTally(round)` |
| `nominatePlayer(playerId)` | `currentVoteTally != null` | Adds `VoteEntry(playerId, 0)` if not already nominated |
| `setVoteCount(playerId, count)` | entry exists in `currentVoteTally` | Updates vote count |
| `resolveVote()` | `currentVoteTally != null` | Computes winner/tie; sets `executedPlayerId` or `wasTied` |
| `confirmExecution(playerId)` | `resolveVote()` called | Checks Fool immunity; marks dead or triggers immunity; `checkAndUpdateResult` |
| `undoLastDeath()` | `deathHistory.isNotEmpty` | Reverts most recent death event; inverse of kill |
| `saveState()` | `state != null` | Serializes to `shared_preferences` |
| `restoreState()` | key exists | Deserializes and sets state |

---

## Night Step Screen Contract (`NightActionScreen`)

**Input** (passed via constructor or read from provider):
- `phase: GamePhase` — contains `scriptText`, `activeRoleIds[0]` (single role per step)
- `round: int`
- `session: GameSession` — for alive player list and ability state

**Output** (via provider mutations before pop):
- Exactly one of: `recordWolfKill`, `recordBodyguardProtect`, `recordWitchSave`/`recordWitchKill`, `recordSeer` called (depending on `activeRoleIds[0]`)
- Screen pops; `GameMasterScreen` advances phase

**Invariants**:
- Witch save option disabled if `abilityState.witchSaveUsed == true`
- Witch kill option disabled if `abilityState.witchKillUsed == true`
- Bodyguard picker excludes `abilityState.lastBodyguardTarget` from selection

---

## Day Voting Screen Contract (`DayVotingScreen`)

**Input**: `session: GameSession` (alive players), `round: int`

**Output** (via provider mutations before pop):
- `beginDayVote()` called on entry
- Zero or more `nominatePlayer` + `setVoteCount` calls
- `resolveVote()` then `confirmExecution(id)` or skip — then pop

**Invariants**:
- At least 2 nominations required to enable "Xác nhận"
- Tie prompt must be resolved before pop is allowed

---

## Role Reference Panel Contract (`RoleReferencePanel`)

**Read-only**: reads `gameProvider` state only. Makes no mutations.

**Displays per role in current game**:
- Role emoji + name
- Full skill description
- Status: alive / dead
- If Witch: "Bình cứu: còn / đã dùng", "Bình độc: còn / đã dùng"
- If Bodyguard: "Bảo vệ đêm qua: {playerName}"
- If Fool: "Miễn tử: còn / đã dùng"

**No navigation side-effects** — purely informational panel.
