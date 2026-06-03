// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'providers/theme_provider.dart';
import 'providers/persistence_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load saved theme before the first frame to avoid a flash or race condition
  // where the async restore inside ThemeModeNotifier could override a user toggle.
  final savedName = await PersistenceService.loadThemeMode();
  final initialMode = savedName == 'light' ? ThemeMode.light : ThemeMode.dark;
  AppColors.brightness = initialMode == ThemeMode.light ? Brightness.light : Brightness.dark;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ProviderScope(
    overrides: [
      themeModeProvider.overrideWith((_) => ThemeModeNotifier(initialMode)),
    ],
    child: const BoardGameMasterApp(),
  ));
}

class BoardGameMasterApp extends ConsumerWidget {
  const BoardGameMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Board Game Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}