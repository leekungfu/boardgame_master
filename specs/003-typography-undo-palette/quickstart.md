# Quickstart: Typography, Per-Phase Undo & Calm Color Palette

## Prerequisites
- Flutter 3.32.7 stable, Dart 3.8.1
- iOS Simulator or Android emulator available
- `flutter pub get` run

## Build order (suggested)

1. **Design tokens (no behavior change yet)**
   - Add `lib/theme/app_colors.dart` (semantic light + dark tokens).
   - Add `lib/theme/app_typography.dart` (type scale → `TextTheme`, Be Vietnam Pro via google_fonts).
   - Rebuild `lib/theme/app_theme.dart` to expose `AppTheme.light` and `AppTheme.dark` from the tokens.
   - Neutralize or remove `lib/theme/app_gradients.dart`.

2. **Theme mode**
   - Add `lib/providers/theme_provider.dart` (`themeModeProvider`, persisted).
   - Add load/save helpers to `PersistenceService`.
   - Wire `MaterialApp` in `main.dart`: `theme`, `darkTheme`, `themeMode`, and a toggle entry on `home_screen.dart`.

3. **Unified undo (state)**
   - In `game_provider.dart`: add `_undoStack`, `_pushSnapshot()`, `canUndo`, `undo()`.
   - Route every mutator through `_pushSnapshot()`; remove/redirect `undoLastDeath`.
   - Clear stack in `startGame()`/`endGame()`.

4. **Undo (UI)**
   - Add `lib/widgets/undo_button.dart` (watches `canUndo`, calls `undo()`, disabled when false).
   - Place it on night_action, day_voting, and game_master screens.

5. **Palette + typography rollout across screens/widgets**
   - Replace per-role colors and raw hex with tokens in the 8 affected files; differentiate roles by icon/label/grouping.

## Verify

```bash
# 1. Static analysis
flutter analyze

# 2. All tests (existing must stay green + new undo/theme tests)
flutter test

# 3. Run on a simulator and play a full game
flutter run
```

### Manual acceptance walkthrough (maps to spec)
1. Start a 7–8 player game, auto-distribute roles.
2. **Undo each phase**: in werewolf/bodyguard/witch/seer steps, make a pick, tap **Undo**, confirm it clears (US1 / U1–U4).
3. Advance a phase by mistake, tap **Undo**, confirm you return to the previous phase with its actions intact (U5).
4. Kill a player to trigger a win, **Undo**, confirm win is cleared and player alive again (U6/U8).
5. Toggle **light/dark**, confirm whole app re-skins; restart app, confirm mode persisted (T1/T2).
6. Inspect every screen: only black/white/grey + red + yellow; roles differ by icon/label not color (P2/P5); Vietnamese names render fully (TY2).
7. Reach a clean win screen with zero errors (X2).

## Done criteria
- `flutter analyze` clean, `flutter test` all pass (SC-007).
- Undo works in 100% of interactive phases (SC-001), ≤ 2 taps / < 5 s (SC-002).
- 100% screens on-palette (SC-003), every color state also has icon/label (SC-004).
- Vietnamese renders correctly, no clipped text on phone sizes (SC-005/006).
