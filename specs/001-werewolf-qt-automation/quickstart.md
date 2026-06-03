# Quickstart: Development & Android Studio Setup

**Feature**: Werewolf QT Automation | **Date**: 2026-05-31

---

## Prerequisites

- Flutter SDK installed at `/Users/tienhoang1211/development/flutter`
- Android SDK at `/Users/tienhoang1211/Library/Android/sdk`
- Android Studio (Arctic Fox or later) with Flutter + Dart plugins installed

---

## 1. Add the new dependency

Open `pubspec.yaml` and add under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  uuid: ^4.4.0
  shared_preferences: ^2.3.2      # ← add this line
```

Then run:

```bash
flutter pub get
```

This is the only new dependency. `shared_preferences` automatically configures the Android and iOS native side via Flutter's plugin system — no manual Gradle edits needed.

---

## 2. Verify Android configuration

`android/local.properties` already has the correct paths for this machine:

```properties
sdk.dir=/Users/tienhoang1211/Library/Android/sdk
flutter.sdk=/Users/tienhoang1211/development/flutter
```

No changes needed. If working on a different machine, update these two lines to match the local SDK locations.

---

## 3. Open in Android Studio

1. Open Android Studio.
2. **File → Open** → select the project root folder (`boardgame_master/`).
3. Android Studio will detect it as a Flutter project via `pubspec.yaml`.
4. Wait for Gradle sync to complete (bottom status bar).

---

## 4. Create a Run/Debug Configuration

1. In the toolbar, click the configuration dropdown (usually says "main.dart" or "No Configurations").
2. Click **Edit Configurations…** (or the `+` icon → **Flutter**).
3. Fill in:
   - **Name**: `boardgame_master`
   - **Dart entrypoint**: `lib/main.dart`
   - **Additional run args**: *(leave blank)*
   - **Build flavor**: *(leave blank)*
4. Click **OK**.

> If the configuration already exists from a previous session, skip this step.

---

## 5. Select a device and run

1. Plug in an Android device with USB debugging enabled, **or** start an Android Virtual Device (AVD) from **Tools → Device Manager**.
2. Select the device from the device dropdown in the toolbar.
3. Press **Run ▶** (Shift+F10) or **Debug 🐛** (Shift+F9).

The app installs and launches. Hot reload is available with **Ctrl+\\** (or the lightning bolt icon).

---

## 6. Run from terminal (alternative)

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Run on the first connected device
flutter run
```

---

## 7. Common issues

| Problem | Solution |
|---------|----------|
| `sdk.dir` not found error | Update `android/local.properties` with your local Android SDK path |
| Gradle sync fails | Run `flutter clean && flutter pub get`, then re-sync |
| `shared_preferences` not found | Run `flutter pub get` after adding the dependency |
| Device not visible in Android Studio | Enable USB debugging on device; run `flutter doctor` to diagnose |
| Hot reload not reflecting model changes | Use hot restart (Shift+\\) instead of hot reload for model changes |

---

## 8. Project structure quick reference

```text
lib/
├── main.dart                           app entry point
├── games/werewolf/
│   ├── werewolf_game.dart              game logic + auto-distribute
│   ├── werewolf_roles.dart             role definitions
│   └── werewolf_presets.dart           balanced preset table (NEW)
├── models/                             data classes
├── providers/
│   ├── game_provider.dart              main state + night/day logic
│   └── persistence_service.dart       JSON save/restore (NEW)
└── screens/
    ├── setup/                          player + role setup
    └── game/                           game master screens (NEW: night, voting, reference)
```
