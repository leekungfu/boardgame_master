import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import 'persistence_service.dart';

/// Holds the moderator-selected theme: only [ThemeMode.light] or [ThemeMode.dark].
///
/// The initial mode is pre-loaded synchronously in `main()` via
/// [ProviderScope.overrides] so there is no async restore race condition — a
/// toggle can never be silently overridden by a late-arriving SharedPreferences
/// read.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initial) : super(initial);

  /// Update, sync the palette static, and persist.
  void setMode(ThemeMode mode) {
    final m = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    AppColors.brightness = m == ThemeMode.light ? Brightness.light : Brightness.dark;
    state = m;
    PersistenceService.saveThemeMode(m.name);
  }

  /// Flip between light and dark.
  void toggle() => setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

// Default fallback (overridden in main() with the pre-loaded saved value).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((_) => ThemeModeNotifier(ThemeMode.dark));
