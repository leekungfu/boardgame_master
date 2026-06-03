# Contract: Per-Phase Undo (state + UI)

The app's "interface" is its `GameNotifier` state API and the on-screen undo control. This contract defines the behavior both must honor.

## State API (`GameNotifier`)

```text
bool get canUndo                  // true iff there is a reversible action to undo
void undo()                       // revert the most recent reversible action; no-op if !canUndo
```

### Behavioral contract

| ID | Given | When | Then | Spec ref |
|---|---|---|---|---|
| U1 | A reversible action was just performed | `undo()` | State equals the snapshot taken immediately before that action (players, abilityState, pendingNight, currentVoteTally, result, phase index) | FR-002 |
| U2 | Multiple actions performed | `undo()` repeatedly | Actions revert in reverse order until stack empty | FR-003 |
| U3 | No action performed yet (fresh game) | read `canUndo` | `false` | FR-004 |
| U4 | Stack exhausted by repeated undo | read `canUndo` | `false`; further `undo()` is a no-op | FR-004 |
| U5 | `nextPhase()` was the last action | `undo()` | `currentPhaseIndex` returns to previous phase; that phase's recorded actions intact | FR-006 |
| U6 | A death (kill/resolveNight/execution/hunter) was last action and had set a win `result` | `undo()` | death reverted **and** `result` restored to the pre-death value (re-evaluated, win cleared if no longer holds) | FR-007 |
| U7 | Any `undo()` | after restore | Only the targeted action and state derived from it differ from post-action state; unrelated fields unchanged | FR-008 |
| U8 | A death was the last action (replaces old `undoLastDeath`) | `undo()` | dead player alive again; `deathHistory` shortened; no regression vs old behavior | FR-009 |

### Invariants
- Every mutating method calls `_pushSnapshot()` **before** changing state.
- `beginNightAction` (idempotent), pure getters, and `_save()` do **not** push snapshots.
- `startGame()` and `endGame()` clear the stack (`canUndo` → false).
- Snapshot captures both `GameSession` and transient `_pendingNight`.

## UI control (`UndoButton` widget)

| ID | Given | When | Then | Spec ref |
|---|---|---|---|---|
| UI1 | Any interactive phase screen (night action, day voting, game master) | screen rendered | An undo control is present | FR-001, FR-020 |
| UI2 | `canUndo == false` | rendered | Control is visibly disabled (or hidden); cannot be tapped | FR-004 |
| UI3 | `canUndo == true` | user taps undo | `undo()` invoked; affected lists/indicators update immediately | FR-005 |
| UI4 | Undo performed | after tap | Restored state is visually reflected (e.g., cleared selection, revived player back in alive list) | FR-005 |
| UI5 | Undo control colors | rendered | Uses palette tokens only; if it signals destructive/danger uses `danger` red with an icon+label (not color alone) | FR-012, FR-014 |
