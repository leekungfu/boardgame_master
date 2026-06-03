import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App theme built on the calm [AppColors] palette (neutral base + red + yellow).
///
/// Legacy token names are retained as **mode-aware getters** so existing call
/// sites keep working while their values now follow the active light/dark mode
/// and collapse onto the approved palette:
///   - former gold/brand `accent`/`accentGlow` → yellow highlight
///   - `accentRed`        → red danger
///   - `accentGreen` and all per-role colors → neutral (roles differ by
///     icon/label/grouping, not color — only red & yellow remain as accents)
///
/// Typography uses **Be Vietnam Pro** (full Vietnamese diacritic coverage) via
/// google_fonts, exposed through a single type scale.
class AppTheme {
  AppTheme._();

  // ─── Semantic colours (mode-aware) ───────────────────────────────────────────
  static Color get background => AppColors.background;
  static Color get surface => AppColors.surface;
  static Color get surfaceVariant => AppColors.surfaceVariant;
  static Color get outline => AppColors.outline;
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get danger => AppColors.danger;
  static Color get highlight => AppColors.highlight;
  static Color get onAccent => AppColors.onAccent;

  // ─── Legacy token aliases (kept so existing widgets compile) ──────────────────
  static Color get night => AppColors.background;
  static Color get nightCard => AppColors.surface;
  static Color get nightCardLight => AppColors.surfaceVariant;
  static Color get dayBg => AppColors.background;
  static Color get accent => AppColors.highlight; // brand → yellow highlight
  static Color get accentGlow => AppColors.highlight;
  static Color get accentRed => AppColors.danger;
  static Color get accentGreen => AppColors.textPrimary; // green folded into neutral

  // Per-role colours collapse to neutral — roles are shown by icon + label.
  static Color get wolfCrimson => AppColors.textPrimary;
  static Color get seerViolet => AppColors.textPrimary;
  static Color get witchEmerald => AppColors.textPrimary;
  static Color get bodyguardCyan => AppColors.textPrimary;
  static Color get hunterAmber => AppColors.textPrimary;
  static Color get foolYellow => AppColors.highlight;

  // ─── Card decorations ─────────────────────────────────────────────────────────
  static BoxDecoration glassCard({Color? borderColor, double radius = 16}) {
    final border = borderColor ?? AppColors.outline;
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 1),
    );
  }

  static BoxDecoration glassCardGlow({required Color glowColor, double radius = 16}) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: glowColor.withOpacity(0.7), width: 1.5),
      );

  // ─── Typography (Be Vietnam Pro — full Vietnamese diacritic support) ──────────
  static TextStyle _font(double size, FontWeight weight, Color color, {double? letterSpacing, double? height}) =>
      GoogleFonts.beVietnamPro(
          fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);

  /// Display/heading style (formerly Cinzel). Defaults to the yellow highlight.
  static TextStyle cinzelDisplay(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      _font(size, weight, color ?? AppColors.highlight, letterSpacing: 0.5);

  /// Body style (formerly Nunito). Defaults to primary text colour.
  static TextStyle nunitoBody(double size, {Color? color}) =>
      _font(size, FontWeight.w400, color ?? AppColors.textPrimary);

  // ─── ThemeData ────────────────────────────────────────────────────────────────
  // Cached as final fields — recreating ThemeData on every build wastes memory
  // and can cause spurious InheritedWidget rebuilds.
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = AppColors.schemeFor(b);
    final onBg = scheme.onSurface;
    final secondary = b == Brightness.light ? const Color(0xFF5A5A5A) : const Color(0xFF9A9A9A);
    final outline = b == Brightness.light ? const Color(0xFFCFCFCF) : const Color(0xFF333333);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor:
          b == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF0E0E0E),
      colorScheme: scheme,
      cardColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: b == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF0E0E0E),
        foregroundColor: onBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.beVietnamPro(
          color: onBg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBg,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      iconTheme: IconThemeData(color: secondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b == Brightness.light ? const Color(0xFFE8E8E8) : const Color(0xFF242424),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: GoogleFonts.beVietnamPro(color: secondary),
        hintStyle: GoogleFonts.beVietnamPro(color: secondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withOpacity(0.30),
        labelStyle: GoogleFonts.beVietnamPro(color: onBg),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: outline,
      // ─── Type scale (display / headline / title / body / label) ──────────────
      textTheme: TextTheme(
        headlineLarge: _font(30, FontWeight.w700, onBg, letterSpacing: 0.5),
        headlineMedium: _font(22, FontWeight.w700, onBg),
        titleLarge: _font(18, FontWeight.w600, onBg),
        bodyLarge: _font(16, FontWeight.w400, onBg),
        bodyMedium: _font(14, FontWeight.w400, secondary),
        labelLarge: _font(13, FontWeight.w600, onBg),
      ),
    );
  }
}
