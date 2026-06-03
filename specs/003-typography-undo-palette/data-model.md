# Phase 1 Data Model: Typography, Per-Phase Undo & Calm Color Palette

This feature adds **state-management** and **design-system** entities. No game-rule entities change. Existing models (`GameSession`, `Player`, `AbilityState`, `NightActionRecord`, `VoteTally`, `DeathEvent`) are unchanged in shape; they are merely captured by the new snapshot entity.

---

## 1. UndoSnapshot (NEW — in-memory only)

Represents the complete reversible state at a moment in time, captured immediately **before** a mutating action.

| Field | Type | Notes |
|---|---|---|
| `session` | `GameSession` | Immutable reference to the session prior to the action |
| `pendingNight` | `NightActionRecord?` | The transient in-progress night record (lives outside `GameSession`) prior to the action |

- **Lifecycle**: created by `_pushSnapshot()` before every mutator; consumed (removed) by `undo()`.
- **Not persisted**: exists only for the running app session.
- **Equality**: reference capture; no deep copy needed because all captured types are immutable with `copyWith`.

## 2. UndoHistory (NEW — in-memory only, inside `GameNotifier`)

| Field | Type | Notes |
|---|---|---|
| `_undoStack` | `List<UndoSnapshot>` | LIFO; top = most recent action |
| cap | `const int` (~50) | When exceeded, oldest entry is dropped |

**Operations** (added to `GameNotifier`):

| Method | Behavior |
|---|---|
| `_pushSnapshot()` | Capture `(state, _pendingNight)`; enforce cap. Called at the start of every mutator. |
| `bool get canUndo` | `_undoStack.isNotEmpty` |
| `void undo()` | Pop top snapshot; restore `state` and `_pendingNight`; `_save()`. No-op if empty. |
| (clear) | `endGame()` / `startGame()` reset `_undoStack` to empty. |

**State transitions**:

```
[action performed] --_pushSnapshot--> stack grows, canUndo = true
[undo()]           --pop+restore-->  state reverts; if stack empty, canUndo = false
[startGame/endGame]                 --> stack cleared, canUndo = false
```

**Reversible actions covered** (each funnels through `_pushSnapshot()` first):
`nextPhase`, `prevPhase`, `killPlayer`, `revivePlayer`, `recordWolfKill`, `recordBodyguardProtect`, `recordWitchSave`, `recordWitchKill`, `clearWitchKill`, `recordSeer`, `resolveNight`, `recordHunterShot`, `nominatePlayer`, `setVoteCount`, `resolveVote`, `confirmExecution`, `nextRound`.

> `undoLastDeath` is **removed/subsumed**: a generic `undo()` after a death restores the pre-death snapshot, which already carries the correct `result` (win re-eval is automatic — FR-007).

**Non-reversible / no snapshot**: `beginNightAction` (idempotent guard), `updateNote` (optional — may be excluded to avoid noisy history), `_save`, pure getters.

---

## 3. AppColors (NEW — design tokens)

Semantic palette, two variants. Exactly one red and one yellow accent; everything else neutral.

| Token | Light variant | Dark variant | Meaning |
|---|---|---|---|
| `background` | near-white `#FFFFFF`/`#FAFAFA` | near-black `#0E0E0E` | App background |
| `surface` | `#F2F2F2` | `#1A1A1A` | Cards/panels |
| `surfaceVariant` | `#E6E6E6` | `#242424` | Secondary surfaces |
| `textPrimary` | `#111111` | `#F2F2F2` | Primary text |
| `textSecondary` | `#5A5A5A` | `#9A9A9A` | Secondary text |
| `outline` | `#CCCCCC` | `#333333` | Borders/dividers |
| `danger` (red) | `#D32F2F` | `#EF5350` | Death / danger / destructive |
| `warning`/`highlight` (yellow) | `#F2B705` | `#FFCC33` | Active selection / warning / highlight |
| `onAccent` | contrast color on red/yellow | contrast color | Text/icon on accent fills |

**Rules** (validation against spec):
- No token outside neutral + red + yellow may be referenced by widgets (FR-010, FR-011).
- `danger` is the only red; `warning` the only yellow (FR-012 — one red, one yellow).
- Accent never the sole signal: paired with icon/label at every use site (FR-014).

## 4. AppTypography / TypeScale (NEW — design tokens)

Single family ("Be Vietnam Pro" via google_fonts), mapped to Flutter `TextTheme` slots.

| Token | TextTheme slot | Approx size / weight | Use |
|---|---|---|---|
| `display` | `headlineLarge` | 30–32 / w700 | Win screen, big titles |
| `headline` | `headlineMedium` | 22–24 / w700 | Screen headers |
| `title` | `titleLarge` | 18 / w600 | Section titles, player names (in-game) |
| `body` | `bodyLarge` | 16 / w400 | Primary body |
| `bodySmall` | `bodyMedium` | 14 / w400 | Secondary body |
| `label` | `labelLarge` | 13 / w600 | Chips, captions, buttons |

**Rules**:
- All screens read from `Theme.of(context).textTheme` so the scale is consistent (FR-015) and inherits the active light/dark palette color.
- Family must render Vietnamese diacritics with no clipping/substitution (FR-017, SC-006).
- Player names + phase instructions use `title`/`body` sizes legible at arm's length (FR-016).

---

## 5. ThemeModePreference (NEW — persisted)

| Field | Type | Notes |
|---|---|---|
| mode | `ThemeMode` (`system` / `light` / `dark`) | Default `system` |
| storage key | `'theme_mode'` in `shared_preferences` | Persisted by `PersistenceService` helpers |

**Provider**: `themeModeProvider` (`StateNotifier<ThemeMode>`); on construction loads persisted value; `setMode()` updates state and persists (FR-014a). `MaterialApp.themeMode` watches it.

**State transitions**:

```
[app start] --load pref--> mode (default system)
[toggle]    --setMode--> state updated + persisted; whole app re-renders in new palette
[app restart] --load pref--> previously selected mode restored
```
