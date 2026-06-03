# Phase 0 Research: Typography, Per-Phase Undo & Calm Color Palette

All Technical Context unknowns were resolvable from the existing codebase plus the two decisions captured during `/speckit-specify`. No external NEEDS CLARIFICATION remain.

---

## R1. Undo architecture — snapshot stack vs inverse commands

**Decision**: Use an **in-memory snapshot history stack** inside `GameNotifier`. Before every state-mutating method, push a snapshot of the current `(GameSession, _pendingNight)` pair onto a bounded stack (cap ~50). `undo()` pops the top snapshot and restores it (including the transient `_pendingNight`), then persists. `canUndo` = stack non-empty.

**Rationale**:
- `GameSession`, `NightActionRecord`, `AbilityState`, `VoteTally` are already immutable with `copyWith`, so a snapshot is just a reference capture — cheap, no deep-copy bugs.
- A single stack uniformly covers *every* phase and action type, including phase advancement (FR-006) and death undo (FR-009 subsumes `undoLastDeath`), without writing bespoke inverse logic per action (which is error-prone and must each re-derive win state).
- "Most recent action within the current phase" (decided scope) is naturally satisfied: the top of the stack is always the most recent action regardless of phase; popping across a phase boundary restores the previous phase exactly (FR-006).
- Win re-evaluation (FR-007) is automatic because the restored snapshot already contains the correct `result` from before the action.

**Alternatives considered**:
- *Inverse-command per action*: each method knows how to reverse itself. Rejected — more code, must hand-maintain win-condition recomputation and `_pendingNight` consistency for each of ~10 actions; high regression risk.
- *Persisting the full undo stack*: rejected — unnecessary; undo is a within-session affordance. Persisting only the active `GameSession` (already done) is enough; history resets on restart, which is acceptable.

**Key implementation notes**:
- Capture must include `_pendingNight` because night actions mutate it outside `GameSession`.
- Introduce one private `_mutate(GameSession Function() compute)` / `_pushSnapshot()` helper so every existing mutator funnels through snapshot capture in one place (avoids missing a method).
- Non-mutating reads (`beginNightAction` idempotency, `_save`) must not push snapshots.
- Cap the stack and drop the oldest when exceeding the cap (memory bound; deep history beyond a phase is out of scope per the decided "most recent action" scope).
- `endGame()`/new game clears the stack.

---

## R2. Theme light+dark with a 2-accent palette

**Decision**: Introduce semantic color tokens in a new `app_colors.dart` with **two `ColorScheme`s** (light + dark) built from: neutral base (white/near-black + greys), `danger` = red, `warning`/`highlight` = yellow. Rebuild `AppTheme` to expose `AppTheme.light` and `AppTheme.dark` `ThemeData`. `MaterialApp` gains `theme`, `darkTheme`, and `themeMode` driven by a Riverpod `theme_provider`. Persist the chosen `ThemeMode` via `shared_preferences`.

**Rationale**:
- Flutter's `MaterialApp.themeMode` + `theme`/`darkTheme` is the idiomatic, zero-dependency way to support both modes and follow/override the system setting (decided requirement FR-014a).
- Centralizing colors as semantic tokens (not raw hex at call sites) is what makes "only red + yellow accents" enforceable and auditable (SC-003).
- `shared_preferences` is already a dependency and already used by `PersistenceService`, so persistence (FR-014a) reuses an established pattern.

**Alternatives considered**:
- *Single dark-only theme with colors stripped*: rejected — the user explicitly chose "tự đổi sáng/tối" (both modes with a toggle).
- *Third-party theming package (e.g. flex_color_scheme)*: rejected — adds a dependency for what core `ThemeData` already does cleanly at this scale.

**Palette token set** (semantic, exact hex finalized in data-model/theme-contract):
`background`, `surface`, `surfaceVariant`, `textPrimary`, `textSecondary`, `outline`, `danger` (red), `warning`/`highlight` (yellow), `onAccent`. Red and yellow keep identical *meaning* in both modes, with shade tuned for contrast against each base.

**Role differentiation without color** (FR-013): roles already use outlined icons (from feature 002). Keep icon + text label + sort/grouping (wolves → special → villagers) as the distinguisher; remove per-role gradient/color tokens (`seerViolet`, `witchEmerald`, `bodyguardCyan`, `hunterAmber`, `foolYellow`, `wolfCrimson`) and `AppGradients.role`.

---

## R3. Typeface with full Vietnamese diacritic support

**Decision**: Replace the Cinzel (display) + Nunito (body) pairing with **"Be Vietnam Pro"** as the primary family for both headings and body (weights for hierarchy), available via `google_fonts`. Optionally keep a single strong weight for display headings. Define a named type scale in `app_typography.dart`.

**Rationale**:
- "Be Vietnam Pro" is purpose-designed for Vietnamese and covers all diacritics/stacked marks without clipping or substitution (FR-017, SC-006) — Cinzel is a Latin display face with weak/again uncertain Vietnamese coverage and is hard to read at a glance during play.
- Available directly through the existing `google_fonts` dependency → no asset bundling, no pubspec font declarations needed.
- A single family with a defined weight/size scale gives consistent hierarchy (FR-015) and better legibility at arm's length (FR-016) than a decorative-display + body mix.

**Alternatives considered**:
- *Keep Cinzel for headings*: rejected — decorative, lower legibility, uncertain Vietnamese diacritic rendering.
- *Bundle custom font files as assets*: rejected — `google_fonts` already covers the chosen family; bundling adds maintenance with no benefit here.
- *Inter / Lexend*: good legibility but Be Vietnam Pro is specifically optimized for the primary (Vietnamese) audience.

**Type scale** (sizes finalized in data-model): `display`, `headline`, `title`, `body`, `bodySmall`, `label` — each mapped to Flutter `TextTheme` slots so widgets using `Theme.of(context).textTheme` inherit automatically.

---

## R4. Test strategy for zero-regression (FR-019, SC-007)

**Decision**: Extend `test/game_notifier_test.dart` with undo coverage for each reversible action and add `test/theme_provider_test.dart` for theme persistence; keep the existing full-game flow test green.

**Rationale**: The provider layer is already unit-testable via `ProviderContainer` (existing pattern). Undo is pure state logic, so it is fully testable without widgets. Theme-mode persistence is testable with `SharedPreferences.setMockInitialValues`.

**Coverage to add**:
- Undo clears a just-selected wolf target / bodyguard / witch / seer and restores prior state.
- Undo reverts a nomination and a vote-count change.
- Undo of phase advancement returns to the previous phase with actions intact.
- Undo of a death re-evaluates win condition (a win that no longer holds is cleared).
- `canUndo` is false at game start and after the stack is exhausted.
- Theme provider persists and restores the selected mode.
