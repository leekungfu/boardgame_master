# Feature Specification: Werewolf App — State Fix & UX Overhaul

**Feature Branch**: `002-werewolf-state-ux-overhaul`

**Created**: 2026-05-31

**Status**: Draft

**Input**: User description: "App này đang bị lỗi ở khá nhiều khâu, việc quản lý state đang chưa được chuẩn, cần phải làm lại đôi chút, cần bổ sung thêm tính năng cho thuận tiện hơn, ví dụ như khi check player nào bị giết thì cần clear và dễ thao tác hơn, quản lý danh sách, đề xuất đội hình cân bằng, sort theo các role, bỏ các icon thay bằng các icon dạng outlined. Và đảm bảo sau khi code xong test các case phải pass toàn bộ, test chơi 1 game với khoảng 7-8 người và end được game với 0 lỗi."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Stable Game Session: No Crashes From Start to End (Priority: P1)

A game moderator (QT) starts a new Werewolf game with 7–8 players, assigns roles (manually or via auto-distribute), runs through every night and day phase, marks deaths correctly, and ends the game cleanly with a win screen — experiencing zero crashes, freezes, or incorrect state throughout the entire session.

**Why this priority**: This is the baseline contract of the app. Every other improvement is useless if the app crashes mid-game. The current mutating-state-before-clone pattern causes stale/shared state bugs.

**Independent Test**: Can be tested end-to-end by starting a 7-player game, running at least 2 full rounds (night + day voting), killing at least 3 players, and reaching the win screen. Delivers a fully functional core loop.

**Acceptance Scenarios**:

1. **Given** a 7-player game is set up with auto-distribute, **When** the QT advances through all night phases (Bodyguard → Werewolf → Seer → Witch) and then all day phases (Discussion → Voting → Execution), **Then** player alive/dead statuses persist correctly across every phase transition and app state reads correctly everywhere on screen.
2. **Given** the Witch used her save potion in round 1, **When** round 2 begins, **Then** the save potion UI is gone and the kill potion is still available (or also gone if used), with no stale state carried over.
3. **Given** a player is killed during the night, **When** the QT taps "Resolve Night", **Then** the dead player immediately disappears from all "alive players" lists on subsequent screens without requiring an app restart.
4. **Given** all werewolves are dead, **When** the QT resolves the night or confirms an execution, **Then** the win screen appears showing "Villagers Win" with no further navigation or interaction required.
5. **Given** the Hunter was executed and their shot is pending, **When** the QT selects a shot target, **Then** the shot is recorded, the target is marked dead, and win condition is checked immediately afterwards.

---

### User Story 2 — Kill/Death Management: Clear, Forgiving, Fast (Priority: P1)

When the QT needs to mark a player as killed (night resolution or day execution), the interaction is streamlined: the dead player is visually distinct, can be toggled back alive (undo) easily, and the screen never requires multiple ambiguous taps to confirm a death.

**Why this priority**: QTs make mistakes under pressure. Currently there is no clear selection confirmation flow, and the kill action lacks visual feedback before committing. An undo mechanism must be fast and obvious.

**Independent Test**: Can be tested by marking 3 players dead during a night phase, then undoing 1 death, and confirming the player list reflects the correct state in the Game Master screen — without advancing phases or triggering vote flows.

**Acceptance Scenarios**:

1. **Given** the night action screen is open, **When** the QT selects a wolf kill target, **Then** a clear "confirm" indicator (selected state with player name) appears before the "Done" action is committed, and tapping again deselects.
2. **Given** a player has just been marked dead, **When** the QT views the Game Master screen, **Then** dead players are shown in a visually distinct state (greyed out, crossed out name, or similar) and cannot be selected for night actions.
3. **Given** the last death was logged, **When** the QT taps "Undo last death", **Then** the most recently killed player is restored to alive status and the win condition is re-evaluated.
4. **Given** the Bodyguard has already protected player A last round, **When** the night action screen opens for Bodyguard this round, **Then** player A is visually blocked from selection with an explanatory label (e.g., "Protected last round").

---

### User Story 3 — Player List: Sortable and Filterable (Priority: P2)

In the Game Master screen and role assignment screen, the QT can sort the player list by role (grouping wolves, special roles, and villagers together) and filter to show only alive or dead players, making it faster to find specific players during a game.

**Why this priority**: With 10+ players, scrolling an unordered list to find a specific role is slow and error-prone mid-game. Sorting and filtering directly reduce the time to act.

**Independent Test**: Can be tested in isolation on the role assignment screen by assigning 8 players varied roles, enabling "sort by role", and verifying wolves appear grouped before special roles and villagers.

**Acceptance Scenarios**:

1. **Given** the role assignment screen shows 8 players with mixed roles, **When** the QT taps "Sort by Role", **Then** the list reorders: Werewolves first, then special villager roles (Seer, Witch, Bodyguard, Hunter, Fool), then plain Villagers.
2. **Given** the Game Master screen shows a mix of alive and dead players, **When** the QT enables the "Alive only" filter, **Then** only alive players are shown and the list updates instantly when a player dies.
3. **Given** the player list is sorted by role, **When** a new death occurs, **Then** the sort order is maintained and the dead player's visual state updates in place.

---

### User Story 4 — Balanced Team Suggestion (Priority: P2)

On the role assignment screen, the app shows the recommended balanced composition for the current player count, and the auto-distribute button applies this preset with one tap. The balance indicator shows wolves vs villagers ratio at a glance.

**Why this priority**: New QTs frequently assign unbalanced teams. A visible suggestion and one-tap preset removes guesswork and makes setup faster for experienced QTs too.

**Independent Test**: Can be tested by opening role assignment with 7 players, verifying the preset recommendation panel shows the correct role counts, tapping auto-distribute, and verifying each player has a role matching the preset — without starting a game.

**Acceptance Scenarios**:

1. **Given** 7 players are in the setup, **When** the role assignment screen opens, **Then** a "Recommended Setup" panel shows the specific roles and counts for 7 players (e.g., 2 Werewolves, 1 Seer, 1 Witch, 1 Bodyguard, 2 Villagers).
2. **Given** the recommended setup panel is visible, **When** the QT taps "Auto-Distribute", **Then** all players are assigned roles matching the recommended preset within 1 second.
3. **Given** the QT manually assigns an unbalanced team (3 wolves, 1 villager), **When** the balance indicator is visible, **Then** it shows a red/warning state with the actual ratio and a clear label that the composition is unbalanced.
4. **Given** the player count is 8, **When** the recommended preset is shown, **Then** it shows a different composition from the 7-player preset and the counts sum to exactly 8.

---

### User Story 5 — Outlined Icons Replace Emoji Icons (Priority: P3)

All emoji used as action icons (buttons, chips, list items) throughout the app are replaced with Material Design outlined icons of the same semantic meaning. Role identity emojis (🐺, 🔮, etc.) displayed as decorative elements may remain, but functional icon elements use outlined icon variants.

**Why this priority**: Emoji rendering is inconsistent across Android versions and device manufacturers. Outlined Material icons render consistently and are more legible at small sizes in dark UI contexts.

**Independent Test**: Can be tested on the role assignment screen by verifying that all tappable icon buttons (delete, reorder, confirm, add) show Material outlined icons rather than emoji, while role display cards retain their decorative emoji.

**Acceptance Scenarios**:

1. **Given** the player setup screen, **When** the QT views the player list, **Then** the delete button uses an outlined icon (`delete_outline`) and the drag handle uses `drag_handle` — no emoji in interactive controls.
2. **Given** the day voting screen, **When** the QT views nominated players, **Then** the increment/decrement buttons use outlined icons (`add_circle_outline`, `remove_circle_outline`) not emoji or filled icons.
3. **Given** any screen with a "confirm" or "done" action button, **When** the button is rendered, **Then** it uses a Material outlined icon variant (`check_circle_outline`, `done`) not an emoji like ✓ or ✅.
4. **Given** role cards displayed on role assignment or reference panel, **When** the QT views them, **Then** the role emoji (🐺, 🔮, 🧪) is retained as decorative role identity — only interactive icon controls are changed.

---

### Edge Cases

- What happens when the Witch's wolf target info is stale (wolf target from a previous night action)? The witch screen must only show the current round's wolf target.
- What happens if the QT taps "Resolve Night" without selecting a wolf kill target? The app should warn or resolve with no wolf kill for that round.
- What happens when all players of one team are dead at game start (e.g., auto-distribute bug)? The app should detect and show an immediate win state.
- How does the system handle a Fool being executed when `foolImmunityUsed` is already true? The Fool should die normally — no double immunity.
- What happens if the QT taps "Next Phase" when already on the last phase without calling `nextRound`? The app must not index out of bounds.
- What happens when `undoLastDeath` is called and the death history is empty? No state change, no crash.
- What happens when a player is killed but has no role assigned? The app must not throw a null error on role access.

---

## Requirements *(mandatory)*

### Functional Requirements

**State Management**

- **FR-001**: The app MUST use fully immutable state — `Player.isAlive` and all other session fields MUST only change via `copyWith` methods; direct field mutation (`p.isAlive = false`) MUST be eliminated.
- **FR-002**: `GameNotifier._clone()` MUST produce a deep copy with no shared mutable list references between the old and new state.
- **FR-003**: All state transitions (kill, revive, vote, phase change) MUST be atomic — the state update must not be observable in a partially updated state.

**Kill/Death UX**

- **FR-004**: The night action screen MUST show a clearly selected state for the chosen kill target, and the selection MUST be cancellable by tapping the same player again.
- **FR-005**: Dead players MUST be visually distinct (greyed out, strikethrough name, or dedicated dead badge) on the Game Master screen and excluded from selection pickers.
- **FR-006**: The "Undo last death" action MUST restore the player to alive and re-evaluate the win condition — available whenever `deathHistory` is non-empty.
- **FR-007**: Night resolution MUST be confirmed via a clear summary step before committing deaths, showing who will die this round.

**Player List Management**

- **FR-008**: The Game Master screen player list MUST support sorting by role (wolves → special roles → plain villagers) and by default order (position/name).
- **FR-009**: The Game Master screen MUST support filtering to show "All players", "Alive only", or "Dead only".
- **FR-010**: Sort and filter state MUST be preserved when the screen is navigated away from and returned to within the same game session.

**Balanced Team Suggestion**

- **FR-011**: The role assignment screen MUST display the recommended preset role composition for the current player count (5–20 players).
- **FR-012**: The "Auto-Distribute" button MUST assign roles matching the recommended preset, distributed randomly among players.
- **FR-013**: The balance indicator MUST show live wolf count vs. villager count and update immediately on every role assignment change.
- **FR-014**: When the current composition is unbalanced (wolves ≥ villagers), the balance indicator MUST show a warning state (red/orange color).

**Icons**

- **FR-015**: All interactive icon controls (buttons, action chips with icons) MUST use Material Design outlined icons; no emoji characters in button or icon widget contexts.
- **FR-016**: Decorative role identity emojis in role cards, script text, and display labels MAY remain as emoji.

**Testing**

- **FR-017**: All existing widget and unit tests MUST pass after changes.
- **FR-018**: A representative 7–8 player game (start → 2 rounds night + day → win condition) MUST complete without runtime errors or assertion failures on both a physical or emulated Android device AND a physical or emulated iOS device — all test cases must be executed on both platforms with identical coverage, no iOS cases skipped.

### Key Entities

- **Player**: Represents a game participant; must be fully immutable (`id`, `name`, `isAlive`, `role` all via `copyWith`).
- **GameSession**: Holds all live game state; must use deep-copied lists on every state update; no shared mutable references.
- **NightActionRecord**: Records per-round night choices (wolf target, bodyguard target, witch actions); scoped to exactly one round and cleared after resolution.
- **DeathEvent**: Immutable record of when, why, and who died; drives undo logic.
- **WerewolfPreset**: Maps player count to recommended role composition; consumed by auto-distribute and the recommended setup panel.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A QT can run a complete 7–8 player game from lobby setup to win screen in under 30 minutes with zero runtime errors or forced restarts — verified independently on both Android and iOS.
- **SC-002**: All automated test cases pass (0 failures) after the overhaul is complete.
- **SC-003**: Every player death action (night kill, execution, hunter shot) is visually confirmed on screen within 1 second of the QT's tap.
- **SC-004**: The "Sort by Role" action reorders the player list in under 100ms for player counts up to 20.
- **SC-005**: The "Auto-Distribute" action assigns all roles in under 500ms for player counts up to 20.
- **SC-006**: Dead players are excluded from all interactive selection lists (night action pickers, vote nomination chips) with 100% reliability — no dead player is ever selectable.
- **SC-007**: Undo last death works correctly in 100% of cases where `deathHistory` is non-empty, restoring the player and re-checking win conditions.

---

## Assumptions

- The app targets both Android and iOS equally; all test cases (unit, widget, and full game integration) must be executed and pass on both platforms with no case excluded on either.
- Player counts of 7–8 are the primary test target; the preset table already covers this range.
- The Fool role immunity edge case (only one use) is already partially implemented — the fix focuses on ensuring it doesn't misfire.
- The current test suite (`test/widget_test.dart`) is the baseline; new tests will be added to cover the critical death/revive/state flows.
- Portrait orientation is enforced at the app level; no landscape handling is in scope.
- No network or backend changes are in scope — the app remains fully offline and single-device.
- The `confetti` package and existing animation infrastructure are retained; no visual style overhaul beyond icon replacement.
- "Outlined icons" means Material Design outlined icon variants already available in the Flutter SDK — no new icon packages are required.
