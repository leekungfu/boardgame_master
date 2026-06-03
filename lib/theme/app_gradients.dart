import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Background/scene gradients, neutralized to the calm palette.
///
/// The previous saturated per-role rainbow gradients have been removed. Every
/// scene now uses a subtle neutral gradient derived from [AppColors], and the
/// single accent used for selections/role highlights is the yellow highlight.
class AppGradients {
  AppGradients._();

  /// Subtle neutral background gradient for the current mode.
  static LinearGradient get _neutral => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.background, AppColors.surface],
      );

  // ─── Scene gradients (all neutral now) ────────────────────────────────────────
  static LinearGradient get deepNight => _neutral;
  static LinearGradient get midnightBlue => _neutral;
  static LinearGradient get crimsonDawn => _neutral;
  static LinearGradient get goldenDay => _neutral;
  static LinearGradient get peaceDay => _neutral;

  /// Role "card" background — neutral surface gradient regardless of role.
  /// Roles are distinguished by icon + label, not colour.
  static LinearGradient forRole(String? roleId) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceVariant, AppColors.surface],
      );

  /// Accent used for a role highlight/selection — the single yellow highlight.
  static Color accentForRole(String? roleId) => AppColors.highlight;
}
