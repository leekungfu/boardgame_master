import 'package:flutter/material.dart';

/// Semantic color palette for the app.
///
/// The whole app uses a calm, restrained palette: a neutral black/white/grey
/// base plus exactly two accent colors — RED for danger/death and YELLOW for
/// highlight/selection/warning. No other saturated colors are used.
///
/// Both a light and a dark variant are provided. [brightness] holds the
/// currently-resolved mode; it is updated by `MaterialApp.builder` so the
/// mode-aware getters below return the right value for the active theme.
class AppColors {
  AppColors._();

  /// Currently active brightness. Set from the resolved theme in
  /// `MaterialApp.builder`, so it also reflects `ThemeMode.system`.
  static Brightness brightness = Brightness.dark;

  static bool get _light => brightness == Brightness.light;

  // ─── Neutral base ─────────────────────────────────────────────────────────
  static Color get background => _light ? const Color(0xFFFFFFFF) : const Color(0xFF0E0E0E);
  static Color get surface => _light ? const Color(0xFFF4F4F4) : const Color(0xFF1A1A1A);
  static Color get surfaceVariant => _light ? const Color(0xFFE8E8E8) : const Color(0xFF242424);
  static Color get textPrimary => _light ? const Color(0xFF141414) : const Color(0xFFF2F2F2);
  static Color get textSecondary => _light ? const Color(0xFF5A5A5A) : const Color(0xFF9A9A9A);
  static Color get outline => _light ? const Color(0xFFCFCFCF) : const Color(0xFF333333);

  // ─── Accents (the ONLY non-neutral colors) ──────────────────────────────────
  /// Danger / death / destructive.
  static Color get danger => _light ? const Color(0xFFD32F2F) : const Color(0xFFEF5350);

  /// Highlight / active selection / warning / primary brand accent.
  static Color get highlight => _light ? const Color(0xFFC79100) : const Color(0xFFFFCC33);

  /// Text/icon color placed on top of an accent fill.
  static Color get onAccent => _light ? const Color(0xFFFFFFFF) : const Color(0xFF111111);

  // ─── ColorScheme builders ───────────────────────────────────────────────────
  static ColorScheme schemeFor(Brightness b) {
    final isLight = b == Brightness.light;
    return ColorScheme(
      brightness: b,
      primary: isLight ? const Color(0xFFC79100) : const Color(0xFFFFCC33),
      onPrimary: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
      secondary: isLight ? const Color(0xFF141414) : const Color(0xFFF2F2F2),
      onSecondary: isLight ? const Color(0xFFFFFFFF) : const Color(0xFF111111),
      error: isLight ? const Color(0xFFD32F2F) : const Color(0xFFEF5350),
      onError: const Color(0xFFFFFFFF),
      surface: isLight ? const Color(0xFFF4F4F4) : const Color(0xFF1A1A1A),
      onSurface: isLight ? const Color(0xFF141414) : const Color(0xFFF2F2F2),
    );
  }
}
