import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:boardgame_master/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to dark when nothing persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('setMode updates state and persists the choice', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Let the async SharedPreferences write complete.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('initial mode passed via constructor is used immediately (no async race)', () {
    // main() pre-loads the saved mode and passes it via ProviderScope.overrides.
    // This test verifies that the override works and there is no async delay.
    final container = ProviderContainer(overrides: [
      themeModeProvider.overrideWith((_) => ThemeModeNotifier(ThemeMode.light)),
    ]);
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('toggle flips between dark and light only', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themeModeProvider.notifier);

    notifier.setMode(ThemeMode.dark);
    notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    notifier.toggle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('setMode never stores system (coerced to dark)', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });
}
