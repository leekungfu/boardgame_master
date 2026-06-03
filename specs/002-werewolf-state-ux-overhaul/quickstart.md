# Quickstart & Test Guide: Werewolf App — State Fix & UX Overhaul

**Feature**: `002-werewolf-state-ux-overhaul`
**Date**: 2026-05-31

---

## Prerequisites

- Flutter SDK ≥ 3.0.0 installed and in `PATH`
- Android Studio with an AVD running API 30+ (or a physical Android device)
- Xcode 15+ with an iOS Simulator (iPhone 14 or later, iOS 16+)
- Run `flutter pub get` from repo root before first run

---

## Run the App

```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator (after opening Xcode once)
flutter run -d "iPhone 15"

# List available devices
flutter devices
```

---

## Run All Tests

```bash
# All unit + widget tests (Dart VM, platform-agnostic)
flutter test

# With coverage report
flutter test --coverage
lcov --summary coverage/lcov.info
```

All tests must pass: 0 failures, 0 errors.

---

## Manual Integration Test Script

Run this script **independently on both Android and iOS**. Do not skip any step on either platform.

### Setup: 7-Player Game

1. Launch app → Home screen visible
2. Tap "Ma Sói" game card → Player setup screen opens
3. Add players: `An`, `Binh`, `Chi`, `Dung`, `Em`, `Phong`, `Giang`
4. Player count badge shows "7 người" ✓
5. Tap "Giao vai trò →" → Role assignment screen opens

### Role Assignment

6. Verify "Đội hình đề xuất (7 người)" panel shows: 2× Ma Sói, 1× Tiên Tri, 1× Phù Thủy, 3× Dân Làng
7. Tap "Auto-Distribute" → all 7 players receive roles within 1 second
8. Balance indicator shows green (wolves < villagers)
9. Tap "Sort by Role" → wolves appear first, then special roles, then villagers
10. Tap "Bắt đầu game" → GameMasterScreen opens on Intro phase

### Round 1 — Night

11. Tap "Tiếp theo →" (advance past intro)
12. Night begins: "Đêm 1" phase visible
13. Advance → Bodyguard phase (if bodyguard present): NightActionScreen opens
    - Select a player to protect → selection highlights
    - Tap same player → deselects (no crash, no stuck selection)
    - Reselect → tap "Confirm / Xác nhận" Done FAB → returns to GameMaster
14. Advance → Werewolf phase: NightActionScreen opens
    - Select player `An` as wolf kill target → selection highlighted
    - Tap Done FAB → returns (no double push, no blank screen)
15. Advance → Seer phase: NightActionScreen opens
    - Select any player → tap Done
16. Advance → Witch phase: NightActionScreen opens
    - Wolf victim shown correctly (player `An`)
    - Tap "Cứu người này" (save potion) → save recorded, option disappears
    - Poison option still visible (if not used)
    - If you accidentally tap poison target → tap again to deselect → no crash, selection cleared
    - Tap Done → returns
17. Advance → "Bình minh" (morning) phase
    - Since `An` was saved: **no deaths announced** ✓
    - Alive player count unchanged from start of round 1

### Round 1 — Day

18. Advance → Discussion phase
19. Advance → Voting phase → DayVotingScreen opens automatically
    - Tap players to nominate: `Binh`, `Chi`
    - Increment `Binh`'s votes to 3, `Chi`'s to 1
    - Vote bar shows `Binh` leading with pulsing highlight
    - Leader icon (`Icons.emoji_events_outlined`) shown next to `Binh`
    - Tap "Xác nhận xử tử" → `Binh` is killed
    - Returns to GameMaster

### Round 2 — Night (without Witch save, trigger wolf kill)

20. Tap "Vòng tiếp theo →" → round 2 night phases load
21. Advance through night phases
22. Werewolf phase: select `Chi` as kill target → Done
23. Witch phase (save already used → save button gone)
    - Kill potion: select `Dung` → tap Done
24. Morning: `Chi` AND `Dung` shown as dead
25. Player list in GameMaster: `Chi` and `Dung` show strikethrough, greyed out
26. `Chi` and `Dung` NOT selectable in alive chips

### Kill/Undo Test

27. In GameMaster, tap alive chip for `Em` → confirm kill dialog → confirm
28. `Em` appears in dead list immediately
29. Tap undo button (top-right, `Icons.undo_outlined`) → `Em` is revived
30. `Em` reappears in alive chips, dead list shrinks

### Win Condition Test

31. Continue killing wolves (use manual kill or let the game progress) until all werewolves are dead
32. Immediately after last wolf is killed: result screen appears showing "Dân Làng Chiến Thắng!"
33. Confetti animation plays
34. Tap "Chơi lại" or "Về màn hình chính" → returns to home screen cleanly

### Filter & Sort Test (mid-game)

35. In GameMaster player list: tap "By Role" sort → wolves grouped at top
36. Tap "Alive only" filter → only alive players shown
37. Mark a player dead → list updates instantly, dead player disappears from view
38. Switch filter to "All" → dead player reappears with strikethrough

---

## 8-Player Variant

Repeat the same script with 8 players and verify:
- Preset shows: 2× Ma Sói, 1× Tiên Tri, 1× Phù Thủy, 1× Hiệp Sĩ, 3× Dân Làng
- Bodyguard protection constraint works (cannot protect same person two nights in a row)

---

## Known Platform Differences to Watch

| Scenario | Android | iOS |
|---|---|---|
| `HapticFeedback.lightImpact()` | Vibration motor | Taptic engine — verify no crash |
| `SharedPreferences` persistence | Works offline | Works offline; verify after app background/foreground |
| `confetti` animation | GPU-rendered | GPU-rendered — verify no frame drops on older simulators |
| Font rendering (Cinzel, Nunito) | `google_fonts` download | Same — verify cached correctly |

---

## Test Pass Criteria

| Check | Android | iOS |
|---|---|---|
| `flutter test` — 0 failures | ✓ | ✓ |
| Full 7-player game, 0 crashes | ✓ | ✓ |
| Full 8-player game, 0 crashes | ✓ | ✓ |
| Wolf kills resolve correctly at morning | ✓ | ✓ |
| Witch save blocks wolf kill | ✓ | ✓ |
| Witch kill deselect clears target | ✓ | ✓ |
| Sort by role groups wolves first | ✓ | ✓ |
| Filter alive/dead updates instantly | ✓ | ✓ |
| Undo last death restores player | ✓ | ✓ |
| Win screen appears on last wolf death | ✓ | ✓ |
| No outlined/emoji icon regressions | ✓ | ✓ |
