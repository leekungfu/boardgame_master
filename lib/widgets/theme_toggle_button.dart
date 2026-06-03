import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Light/dark toggle, available throughout the app (home + during gameplay).
/// Two states only — sun for light, moon for dark.
class ThemeToggleButton extends ConsumerWidget {
  final double size;
  final VisualDensity? visualDensity;
  const ThemeToggleButton({super.key, this.size = 22, this.visualDensity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      icon: Icon(
        isDark ? PhosphorIconsFill.moon : PhosphorIconsFill.sun,
        color: AppTheme.textSecondary,
        size: size,
      ),
      visualDensity: visualDensity,
      tooltip: isDark ? 'Chế độ tối (chạm để sang sáng)' : 'Chế độ sáng (chạm để sang tối)',
      onPressed: () {
        HapticFeedback.lightImpact();
        ref.read(themeModeProvider.notifier).toggle();
      },
    );
  }
}
