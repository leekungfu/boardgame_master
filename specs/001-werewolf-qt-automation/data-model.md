# Data Model: Werewolf QT Automation

**Phase 1 output** | **Date**: 2026-05-31

---

## Existing Models (unchanged or minimally extended)

### `Role` (lib/models/role.dart) — unchanged
```
Role
  id: String            (e.g., 'werewolf', 'seer')
  name: String          (display name in Vietnamese)
  emoji: String
  team: RoleTeam        (villager | werewolf | neutral)
  description: String
  hasNightAction: bool
  nightOrder: int       (execution order, lower = earlier)
```

### `Player` (lib/models/player.dart) — unchanged
```
Player
  id: String
  name: String
  isAlive: bool
  role: Role?
```

### `GamePhase` (lib/models/game_phase.dart) — EXTENDED
```
GamePhase
  id: String
  name: String
  description: String        (short label for progress bar)
  scriptText: String         (NEW: full narration QT reads aloud; empty = no script)
  isNight: bool
  durationSeconds: int
  activeRoleIds: List<String>
  phaseType: PhaseType       (NEW: nightStep | morning | dayDiscussion | dayVoting | special)
```

`PhaseType` enum drives which screen is shown:
- `nightStep` → `NightActionScreen`
- `morning` → inline announcement in `GameMasterScreen`
- `dayDiscussion` → inline in `GameMasterScreen`
- `dayVoting` → `DayVotingScreen`
- `special` → `GameMasterScreen` with interrupt prompt (Hunter, Fool)

---

## New Models

### `AbilityState` (lib/models/ability_state.dart)
Tracks consumable/stateful abilities for the current game session.

```
AbilityState
  witchSaveUsed: bool          (default false; set true when save potion consumed)
  witchKillUsed: bool          (default false; set true when kill potion consumed)
  foolImmunityUsed: bool       (default false; set true after first vote-execution)
  hunterShotPending: bool      (default false; set true on Hunter death, cleared after shot)
  hunterShotTarget: String?    (playerId chosen by Hunter)
  lastBodyguardTarget: String? (playerId; prevents same-night repeat protection)

Serialization: toJson() / fromJson() for persistence
```

### `NightActionRecord` (lib/models/night_action_record.dart)
One record per round capturing all night outcomes before resolution.

```
NightActionRecord
  round: int
  wolfTarget: String?          (playerId chosen by Wolves; null = no kill)
  bodyguardTarget: String?     (playerId protected; null = Bodyguard dead/skipped)
  witchSaveTarget: String?     (playerId saved; null = save not used this night)
  witchKillTarget: String?     (playerId poisoned; null = kill not used this night)
  seerTarget: String?          (playerId inspected)
  seerResultIsWolf: bool?      (true = wolf, false = not wolf; null = not used)
  resolved: bool               (false until resolveNight() called)

Computed (resolved phase):
  died: List<String>           (playerIds who die this night after all interactions)

Serialization: toJson() / fromJson()
```

**Resolution logic** (applied in `resolveNight()`):
```
blocked = {}
if bodyguardTarget != null → blocked.add(bodyguardTarget)
if witchSaveTarget != null → blocked.add(witchSaveTarget)

died = []
if wolfTarget != null && wolfTarget not in blocked → died.add(wolfTarget)
if witchKillTarget != null → died.add(witchKillTarget)
```

### `VoteTally` (lib/models/vote_tally.dart)
Captures the day execution vote for one round.

```
VoteTally
  round: int
  nominations: List<VoteEntry>  (ordered by nomination time)
  resolved: bool
  executedPlayerId: String?     (null = no execution / tie not resolved)
  wasTied: bool

VoteEntry
  playerId: String
  voteCount: int
```

**Resolution logic**:
```
maxVotes = max(nominations.map(e => e.voteCount))
winners = nominations.where(e => e.voteCount == maxVotes)
if winners.length == 1 → executedPlayerId = winners.first.playerId
else → wasTied = true, show tie resolution prompt to QT
```

### `RolePreset` (lib/games/werewolf/werewolf_presets.dart)

```
RolePreset
  playerCount: int
  roleCounts: Map<String, int>   (roleId → count)

static Map<int, RolePreset> table   (keyed by player count 5–20)
```

---

## Extended Model

### `GameSession` (lib/models/game_session.dart) — EXTENDED
New fields added alongside existing fields:

```
GameSession (existing fields unchanged)
  + abilityState: AbilityState          (initialized fresh on game start)
  + nightLog: List<NightActionRecord>   (one per completed round)
  + currentVoteTally: VoteTally?        (active day vote; null outside day phase)
  + deathHistory: List<DeathEvent>      (for undo support)

DeathEvent (inline class or small model)
  playerId: String
  round: int
  cause: DeathCause    (wolfKill | witchPoison | execution | hunterShot)
```

---

## State Transitions

```
Game start
  → AbilityState() (all false/null)
  → nightLog = []

Each night (round N):
  → NightActionRecord(round: N) created
  → QT records actions step by step
  → resolveNight() called → record.died computed → record.resolved = true
  → Players in record.died marked isAlive = false
  → If Hunter in died → abilityState.hunterShotPending = true
  → nightLog.add(record)
  → checkWinCondition()

Each day:
  → VoteTally(round: N) created
  → QT nominates + enters votes
  → Resolution: executedPlayerId set
  → If Fool + !foolImmunityUsed → skip death, set foolImmunityUsed = true
  → Else → mark player dead
  → If Hunter executed → abilityState.hunterShotPending = true
  → checkWinCondition()
  → currentVoteTally = resolved tally
```

---

## Persistence Schema

Stored as single JSON key `active_game_session` in `shared_preferences`:

```json
{
  "gameId": "werewolf",
  "round": 2,
  "currentPhaseIndex": 4,
  "result": "ongoing",
  "qtNote": "...",
  "players": [...],
  "abilityState": {
    "witchSaveUsed": false,
    "witchKillUsed": false,
    "foolImmunityUsed": false,
    "hunterShotPending": false,
    "hunterShotTarget": null,
    "lastBodyguardTarget": "player-uuid-1"
  },
  "nightLog": [...],
  "currentVoteTally": null
}
```

`GamePhase` list is **not** persisted — it is rebuilt from `WerewolfGame.buildRoundPhases()` using the persisted `round` and alive player list on restore.
