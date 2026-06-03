# Feature Specification: Typography, Per-Phase Undo & Calm Color Palette

**Feature Branch**: `003-typography-undo-palette`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "Cải thiện font chữ cho ứng dụng và thêm các nút undo ở mỗi giai đoạn để chẳng may nếu có pick nhầm thì còn chọn lại được vì đôi khi trong quá trình chơi sẽ có những khoảnh khắc nhầm lẫn. Ngoài ra thì cần giảm tải lại các màu quá sặc sỡ, làm sao để cái app nó có màu chủ đạo, tôi nghĩ chỉ cần màu trắng đen hoặc thêm đỏ, vàng thôi."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Undo a Mistaken Pick at Any Phase (Priority: P1)

During a live game, the moderator (QT) is moving fast and sometimes taps the wrong player or confirms a step too early — for example selecting the wrong werewolf kill target, marking the wrong player as protected, recording the wrong seer check, nominating the wrong player for a vote, or advancing to the next phase prematurely. At every phase of the game, the moderator can undo the most recent action and re-pick correctly, without restarting the game or losing the rest of the game state.

**Why this priority**: Mis-taps under time pressure are the single most disruptive event in a real session. Today only "undo last death" exists; mistakes in night-action picks, votes, and phase advancement cannot be reverted, forcing an awkward verbal correction or a game restart. A consistent undo at every phase directly protects the integrity of every game.

**Independent Test**: Can be fully tested by running through each phase (werewolf kill, bodyguard protect, witch save/kill, seer check, day nomination/vote, and phase advance), deliberately making a wrong pick in each, tapping Undo, and confirming the state returns exactly to the moment before the wrong pick — delivering a forgiving, mistake-tolerant moderation flow.

**Acceptance Scenarios**:

1. **Given** the werewolf night step with a kill target already selected, **When** the QT taps "Undo", **Then** the selected kill target is cleared and the QT can select a different target before confirming.
2. **Given** the bodyguard step where the QT just recorded a protection on the wrong player, **When** the QT taps "Undo", **Then** the protection record is removed and the bodyguard step returns to its pre-selection state.
3. **Given** the witch step where a save or kill potion was just applied, **When** the QT taps "Undo", **Then** that potion action is reverted, the potion is shown as available again, and the affected player's pending status is restored.
4. **Given** the seer step where a check was just recorded against the wrong player, **When** the QT taps "Undo", **Then** the seer result is discarded and the QT can re-check the intended player.
5. **Given** the day voting phase with a player just nominated or a vote count just entered, **When** the QT taps "Undo", **Then** the most recent nomination or vote-count change is reverted.
6. **Given** the QT advanced to the next phase by mistake, **When** the QT taps "Undo" (or a clearly labeled "Back" control), **Then** the game returns to the previous phase with the previous phase's recorded actions intact.
7. **Given** an action has just been undone, **When** the QT views the screen, **Then** there is clear visual confirmation of what was reverted (e.g., the control reflects the restored state) and the undo control disables itself when there is nothing left to undo in the current phase.

---

### User Story 2 — Calm, Consistent Color Palette (Priority: P2)

The current app uses many saturated colors (gold, crimson, violet, emerald, cyan, amber, yellow gradients) that feel visually noisy. The moderator wants a calm, consistent look built around a single dominant palette — black and white as the base, with red and yellow reserved as the only accent colors used sparingly to signal meaning (e.g., danger/death and warning/highlight). The palette is offered in both a light (white-base) and dark (black-base) variant that the moderator can switch between.

**Why this priority**: A noisy, multi-color interface increases cognitive load and makes it harder to spot the information that matters during a fast-moving game. A restrained palette improves readability and gives the app a coherent identity. It is high-value but does not block running a game, so it ranks below the undo capability.

**Independent Test**: Can be tested by navigating every screen (setup, role assignment, game master, night action, day voting, win/end) and confirming that the only colors used are the black/white neutral base plus red and yellow accents — with no violet, emerald, cyan, or rainbow gradients remaining.

**Acceptance Scenarios**:

1. **Given** any screen in the app, **When** it is displayed, **Then** its background, surfaces, and text use a neutral black/white/grey base, and the only non-neutral colors present are red and yellow.
2. **Given** a status that signals danger or death, **When** it is shown, **Then** it uses the red accent consistently across all screens (one red, not several reds).
3. **Given** a status that signals a warning, an active selection, or an important highlight, **When** it is shown, **Then** it uses the yellow accent consistently across all screens.
4. **Given** role cards and role indicators that previously used per-role colors, **When** they are displayed, **Then** roles are distinguished by label, icon, and/or grouping rather than by a unique saturated color per role.
5. **Given** the previous multi-color gradients, **When** screens render, **Then** large saturated gradient backgrounds are removed or replaced with the neutral base.
6. **Given** the moderator switches between light and dark mode, **When** the mode changes, **Then** the entire app re-renders with the corresponding palette variant (white-base or black-base) while the red and yellow accent semantics stay consistent, and the chosen mode is remembered.

---

### User Story 3 — Improved, Legible Typography (Priority: P3)

The moderator finds the current fonts hard to read at a glance during play. Typography is refined so that text is clear and legible at the distances and speeds of real gameplay: a consistent type scale, comfortable sizes, and clear contrast between the base and accent palette.

**Why this priority**: Legibility affects every interaction, but the current fonts are functional, so this is a polish improvement rather than a blocker. It complements the palette refresh in User Story 2.

**Independent Test**: Can be tested by reviewing each screen for a consistent, legible type scale — headings, player names, body text, and labels are each rendered at a readable size with clear hierarchy — and confirming no text is clipped, truncated unexpectedly, or too small to read at arm's length.

**Acceptance Scenarios**:

1. **Given** any screen, **When** text is displayed, **Then** headings, body text, player names, and secondary labels follow a single consistent type scale with clear visual hierarchy.
2. **Given** the player list during a game, **When** a moderator glances at it from arm's length, **Then** player names are large and legible enough to read without leaning in.
3. **Given** the chosen typeface, **When** it renders Vietnamese text with diacritics, **Then** all accented characters display correctly without clipping or substitution.

---

### Edge Cases

- **Nothing to undo**: When a phase has had no actions yet, the Undo control is visible but disabled (or hidden) so the moderator cannot undo into an undefined state.
- **Undo across phase boundary**: When the moderator undoes immediately after advancing a phase, the system must restore the previous phase and its recorded actions rather than silently doing nothing.
- **Undo after death resolution**: Undoing a witch/wolf action after the night has been resolved must keep the resulting alive/dead state consistent (no "ghost" deaths or revived players left in a wrong state). If undo is not safe after resolution, the control must clearly indicate the boundary.
- **Win condition interaction**: When an undo reverts a death that had triggered a win, the win state must be re-evaluated and cleared if the game is no longer over.
- **Repeated undo**: Tapping undo multiple times reverts actions in reverse order within the allowed scope; the control disables once the scope's history is exhausted.
- **Color accessibility**: Red and yellow accents must remain distinguishable for color-blind users (e.g., paired with an icon or label, not color alone).
- **Long player names**: Larger typography must not cause important controls or names to overflow or become clipped on smaller phone screens.

## Requirements *(mandatory)*

### Functional Requirements

#### Per-Phase Undo

- **FR-001**: The system MUST provide an undo control on every interactive game phase (werewolf kill, bodyguard protect, witch save, witch kill, seer check, day nomination, day vote-count entry, and phase advancement).
- **FR-002**: Undo MUST revert the single most recent reversible action in the current scope and restore the state to exactly what it was immediately before that action.
- **FR-003**: The system MUST allow repeated undo, reverting actions in reverse chronological order until the current scope's reversible history is exhausted.
- **FR-004**: The undo control MUST be disabled or hidden when there is no reversible action available, and MUST become active as soon as a reversible action is performed.
- **FR-005**: After an undo, the system MUST provide clear visual confirmation that the action was reverted and reflect the restored state in all relevant on-screen lists and indicators.
- **FR-006**: Undoing a phase advancement MUST return the game to the previous phase with that phase's previously recorded actions preserved.
- **FR-007**: When an undo reverts a death or other win-affecting action, the system MUST re-evaluate the win condition and clear any win/end state that no longer applies.
- **FR-008**: Undo MUST NOT corrupt unrelated game state — only the targeted action and state derived from it may change.
- **FR-009**: The existing "undo last death" capability MUST be preserved or subsumed by the unified undo behavior without regression.

#### Color Palette

- **FR-010**: The app MUST adopt a single dominant color palette consisting of a neutral black/white/grey base plus exactly two accent colors: red and yellow.
- **FR-011**: The system MUST remove or replace previously used saturated colors that fall outside the approved palette (e.g., violet, emerald, cyan, gold gradients, multi-stop rainbow gradients).
- **FR-012**: The red accent MUST be used consistently for danger/death semantics across all screens; the yellow accent MUST be used consistently for warning/active-selection/highlight semantics.
- **FR-013**: Roles that were previously distinguished by unique colors MUST instead be distinguished by label, icon, and/or grouping while conforming to the approved palette.
- **FR-014**: Accent colors MUST NOT be the sole means of conveying meaning; each color-coded state MUST also carry a text label or icon for accessibility.
- **FR-014a**: The app MUST provide both a light (white-base) and a dark (black-base) variant of the palette and MUST let the moderator switch between them; the selected mode MUST persist across app restarts. Red and yellow accent semantics MUST remain identical in both modes, with contrast preserved against each base.

#### Typography

- **FR-015**: The app MUST use a consistent type scale with clear hierarchy across all screens (headings, titles, body, player names, secondary labels).
- **FR-016**: Typography MUST be legible at arm's length for the primary in-game content (player names and current-phase instructions).
- **FR-017**: The chosen typeface(s) MUST correctly render Vietnamese text including all diacritics without clipping or character substitution.
- **FR-018**: Text MUST NOT be clipped, overlap, or overflow its container on supported phone screen sizes under the new type scale.

#### Cross-Cutting

- **FR-019**: All existing automated tests MUST continue to pass after these changes, and a full sample game (7–8 players) MUST be playable from start to a clean end with zero errors.
- **FR-020**: The visual and undo changes MUST apply consistently across all existing screens (setup, role assignment, game master, night action, day voting, win/end).

### Key Entities *(include if feature involves data)*

- **Reversible Action**: A record of a single moderator action that can be undone (type, target, phase/round context, and the prior state needed to restore it). Ordered as a per-scope history so the most recent action is undone first.
- **Undo Scope**: The boundary within which undo operates for the current phase (e.g., current night step, current vote, or phase-advancement step). Defines which actions are reversible and when the undo control disables.
- **Palette Token**: A named semantic color (base, surface, text-primary, text-secondary, danger=red, warning/highlight=yellow) that every screen references instead of hard-coded saturated colors.
- **Type Scale Token**: A named text style (display/heading/title/body/label) defining size, weight, and role, referenced consistently across screens.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a full sample game of 7–8 players, the moderator can undo a mistaken pick in 100% of interactive phases (night actions, votes, and phase advancement) and return to the correct state without restarting.
- **SC-002**: Recovering from a mis-tap via undo takes no more than 2 taps and under 5 seconds.
- **SC-003**: 100% of screens use only the approved palette (neutral base + red + yellow); zero screens display out-of-palette saturated colors or rainbow gradients.
- **SC-004**: Every color-coded state on every screen is also distinguishable without relying on color alone (carries an icon or text label).
- **SC-005**: All player names and current-phase instructions are legible at arm's length, and no text is clipped or overflowing on supported phone sizes.
- **SC-006**: Vietnamese text with diacritics renders correctly on 100% of screens with no clipped or substituted characters.
- **SC-007**: 100% of existing automated tests pass, and a 7–8 player game can be played start to clean end with zero errors.

## Assumptions

- **Undo scope (decided)**: Undo reverts the most recent reversible actions within the current phase/step, one action per tap, not an unlimited full-game time-machine. This matches the "pick nhầm thì chọn lại" intent of correcting a recent mistake.
- **Palette base (decided)**: "Trắng đen + đỏ, vàng" is a neutral monochrome base with red and yellow as the only two accent colors, offered as BOTH a light (white-base) and dark (black-base) variant with a moderator-controlled toggle that persists across restarts.
- The app remains a single-device moderator tool (no multi-user/online sync), consistent with the existing implementation.
- Existing role/phase logic and game rules are unchanged; this feature changes presentation (typography, color) and adds reversibility (undo), not game rules.
- Vietnamese is the primary display language and must be fully supported by the chosen typeface.
- Target platform is mobile phone screen sizes (the app already runs on iOS/Android), so legibility and overflow are judged on phone form factors.
