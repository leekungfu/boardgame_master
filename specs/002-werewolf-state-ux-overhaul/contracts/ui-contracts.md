# UI Contracts: Werewolf App — State Fix & UX Overhaul

**Feature**: `002-werewolf-state-ux-overhaul`
**Date**: 2026-05-31

---

## Contract 1 — GameMasterScreen: Player List Sort & Filter

### Controls (placed in `_buildAppBar` or a sub-header row)

```
[ Sort: Default | By Role ]   [ Filter: All | Alive | Dead ]
```

- Both controls are `SegmentedButton` or twin `TextButton` toggles
- Persist in local widget state (`_sortMode`, `_filterMode`)
- Default on game start: `default_` sort, `all` filter

### Player Row Display (dead players)

- Dead player: name with `TextDecoration.lineThrough`, text color `AppTheme.textSecondary`, role emoji at 50% opacity
- Dead player trailing icon: `Icons.favorite_border` (outlined) — tapping calls `revivePlayer()`; color `AppTheme.accentGreen`
- Alive player trailing: `Icons.close` — opens kill confirmation dialog; color `AppTheme.accentRed`

### Undo Last Death Button

- Shown in app bar only when `session.deathHistory.isNotEmpty`
- Icon: `Icons.undo_outlined`
- Tap: calls `gameProvider.notifier.undoLastDeath()`
- No confirmation dialog needed (low-risk, reversible)

---

## Contract 2 — RoleAssignmentScreen: Preset Recommendation Panel

### Layout

```
┌─────────────────────────────────────────────┐
│ Đội hình đề xuất (7 người)                  │
│                                             │
│  🐺 Ma Sói    × 2    🔮 Tiên Tri  × 1      │
│  🧪 Phù Thủy  × 1    👨‍🌾 Dân Làng  × 3      │
│                                             │
│           [ Auto-Distribute ]               │
└─────────────────────────────────────────────┘
```

- Panel appears below the player count badge, above the player list
- Panel is only shown when `WerewolfPresets.table[playerCount] != null`
- Role counts shown as `RoleChip` pairs: role emoji + role name + `× N`
- "Auto-Distribute" button: full-width `ElevatedButton`, calls `setupProvider.notifier.autoDistribute()`
- If fewer than 5 players: hide panel entirely (no preset available)

### Balance Indicator

- Located below the player list (existing `_balanceLabel`/`_balanceColor` logic — keep)
- **Replace** wolf/villager emoji with text: `"Ma Sói: N  |  Làng: M"`
- Keep color logic: green when wolves < villagers, red otherwise
- Add icon: `Icons.balance_outlined` before the text

---

## Contract 3 — NightActionScreen: Selection & Witch Fix

### Selection State

- Tapping a player toggles `_selectedPlayerId` (tap selected → deselects)
- For witch kill target: deselect clears `_pendingNight.witchKillTarget` via `clearWitchKill()` on the provider
- "Done" FAB label changes based on context:
  - No selection → "Skip / Bỏ qua"
  - Selection made → "Confirm / Xác nhận"
- FAB icon: `Icons.check_circle_outline` (not emoji)

### No Wolf Target Warning

- If wolf phase and `_selectedPlayerId == null` when Done tapped: show `SnackBar` "Ma Sói chưa chọn mục tiêu — đêm nay không ai bị giết" and proceed
- No blocking alert; QT decides

---

## Contract 4 — Icon Replacement Map

| Location | Old | New |
|---|---|---|
| `_PlayerRow` trailing revive | `Icons.favorite` | `Icons.favorite_border` |
| `GameMasterScreen` FAB reference | `Text('📖')` | `Icon(Icons.menu_book_outlined)` |
| `GameMasterScreen` undo button | (new) | `Icon(Icons.undo_outlined)` |
| `DayVotingScreen` increment | `Icons.add` | `Icons.add_circle_outline` |
| `DayVotingScreen` decrement | `Icons.remove` | `Icons.remove_circle_outline` |
| `DayVotingScreen` leader indicator | `Text('👑')` | `Icon(Icons.emoji_events_outlined)` |
| `NightActionScreen` Done FAB | `Icon(Icons.check)` | `Icon(Icons.check_circle_outline)` |
| `RoleAssignmentScreen` balance | emoji prefix | `Icon(Icons.balance_outlined)` |
| `PlayerSetupScreen` delete | `Icons.delete_outline` | keep (already outlined) |
| `DayVotingScreen` AppBar | `'Bỏ Phiếu 🗳️'` | `'Bỏ Phiếu'` (remove emoji from title) |

**Retained decorative emojis** (do NOT replace):
- Role emoji in `Text` widgets inside role cards, chip labels, script cards
- Death cause display emojis in `_MorningAnnouncement`
- Win screen decorative emojis (🎉, 🐺)

---

## Contract 5 — GameNotifier Public API Changes

| Method | Change |
|---|---|
| `killPlayer(id)` | Rewritten: immutable via `copyWith`; no `checkAndUpdateResult` call needed separately — win check included |
| `revivePlayer(id)` | Rewritten: immutable |
| `beginNightAction(round)` | Called by `GameMasterScreen` before pushing night screen; not a no-op anymore |
| `recordWolfKill(id)` | `_pendingNight = _pendingNight!.copyWith(wolfTarget: id)` |
| `recordWitchKill(id)` | `_pendingNight = _pendingNight!.copyWith(witchKillTarget: id)` |
| `clearWitchKill()` | NEW: `_pendingNight = _pendingNight!.copyWith(witchKillTarget: null)` |
| `resolveNight(game)` | Called from `GameMasterScreen` when entering morning phase; not after each screen pop |
| `setVoteCount(id, count)` | Rewritten: uses `copyWith` on `VoteEntry` + `VoteTally` |
| `resolveVote()` | Rewritten: uses `VoteTally.resolve()` returning new instance |
| `_clone(s)` | REMOVED: replaced by `state!.copyWith(...)` everywhere |
