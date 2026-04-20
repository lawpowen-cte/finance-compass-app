import 'package:flutter/material.dart';

import '../settings/app_theme_style.dart';

class FinanceThemePalette {
  const FinanceThemePalette({
    required this.seed,
    required this.background,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.cardTint,
    required this.cardBorderStrong,
    required this.textPrimary,
    required this.textMuted,
    required this.gradient,
  });

  final Color seed;
  final Color background;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color cardTint;
  final Color cardBorderStrong;
  final Color textPrimary;
  final Color textMuted;
  final List<Color> gradient;
}

FinanceThemePalette paletteForStyle(AppThemeStyle style) {
  switch (style) {
    case AppThemeStyle.tide:
      return const FinanceThemePalette(
        seed: Color(0xFF4F8F86),
        background: Color(0xFFF3F5F8),
        backgroundTop: Color(0xFFF9FBFD),
        backgroundBottom: Color(0xFFEFF2F7),
        surface: Color(0xFFFDFDFE),
        surfaceAlt: Color(0xFFE9EEF4),
        border: Color(0xFFD7DEE7),
        cardTint: Color(0xFFE7F3F0),
        cardBorderStrong: Color(0xFF9ABFB8),
        textPrimary: Color(0xFF315955),
        textMuted: Color(0xFF6B7280),
        gradient: [Color(0xFF8EC5BC), Color(0xFFD5E7E2)],
      );
    case AppThemeStyle.ocean:
      return const FinanceThemePalette(
        seed: Color(0xFF0E7490),
        background: Color(0xFFEAF4F8),
        backgroundTop: Color(0xFFF4FBFE),
        backgroundBottom: Color(0xFFDDECF4),
        surface: Color(0xFFF9FDFF),
        surfaceAlt: Color(0xFFD6EAF3),
        border: Color(0xFFC2DAE6),
        cardTint: Color(0xFFD9EFF8),
        cardBorderStrong: Color(0xFF76B9D3),
        textPrimary: Color(0xFF15556C),
        textMuted: Color(0xFF587383),
        gradient: [Color(0xFF2D9CDB), Color(0xFF8FD3F4)],
      );
    case AppThemeStyle.sky:
      return const FinanceThemePalette(
        seed: Color(0xFF4F83CC),
        background: Color(0xFFEEF4FF),
        backgroundTop: Color(0xFFF8FBFF),
        backgroundBottom: Color(0xFFDFEAFE),
        surface: Color(0xFFFBFDFF),
        surfaceAlt: Color(0xFFE2EBFC),
        border: Color(0xFFC9D8F1),
        cardTint: Color(0xFFE1EBFF),
        cardBorderStrong: Color(0xFF8FB0E2),
        textPrimary: Color(0xFF365988),
        textMuted: Color(0xFF61708C),
        gradient: [Color(0xFF7FB3FF), Color(0xFFCFE0FF)],
      );
    case AppThemeStyle.ember:
      return const FinanceThemePalette(
        seed: Color(0xFFCC7A54),
        background: Color(0xFFF6F4F3),
        backgroundTop: Color(0xFFFCFAF8),
        backgroundBottom: Color(0xFFF1EBE8),
        surface: Color(0xFFFDFCFB),
        surfaceAlt: Color(0xFFF3E7DE),
        border: Color(0xFFE3D8D0),
        cardTint: Color(0xFFF6E8DF),
        cardBorderStrong: Color(0xFFD8AB8E),
        textPrimary: Color(0xFF7A4E34),
        textMuted: Color(0xFF7A6E67),
        gradient: [Color(0xFFF1C8AF), Color(0xFFF8E5D8)],
      );
    case AppThemeStyle.forest:
      return const FinanceThemePalette(
        seed: Color(0xFF708C64),
        background: Color(0xFFF2F5F0),
        backgroundTop: Color(0xFFF8FBF6),
        backgroundBottom: Color(0xFFEAF0E6),
        surface: Color(0xFFFDFEFC),
        surfaceAlt: Color(0xFFE8EEDF),
        border: Color(0xFFD7DFD2),
        cardTint: Color(0xFFE7F0E1),
        cardBorderStrong: Color(0xFFA2B897),
        textPrimary: Color(0xFF48613F),
        textMuted: Color(0xFF6B7566),
        gradient: [Color(0xFFB8CCA5), Color(0xFFE1EAD7)],
      );
    case AppThemeStyle.dune:
      return const FinanceThemePalette(
        seed: Color(0xFFB7794D),
        background: Color(0xFFF8F1E9),
        backgroundTop: Color(0xFFFEFAF5),
        backgroundBottom: Color(0xFFF0E1D0),
        surface: Color(0xFFFFFCF8),
        surfaceAlt: Color(0xFFF2E3D3),
        border: Color(0xFFE6D2BF),
        cardTint: Color(0xFFF6E7D6),
        cardBorderStrong: Color(0xFFD2A780),
        textPrimary: Color(0xFF875833),
        textMuted: Color(0xFF866B5A),
        gradient: [Color(0xFFE3B587), Color(0xFFF5E1C8)],
      );
    case AppThemeStyle.aurora:
      return const FinanceThemePalette(
        seed: Color(0xFF6D5BD0),
        background: Color(0xFFF2F0FB),
        backgroundTop: Color(0xFFFAF8FF),
        backgroundBottom: Color(0xFFE6E0FA),
        surface: Color(0xFFFEFDFF),
        surfaceAlt: Color(0xFFEAE6FB),
        border: Color(0xFFD7D1F0),
        cardTint: Color(0xFFEEEAFE),
        cardBorderStrong: Color(0xFFAA9CE6),
        textPrimary: Color(0xFF51429A),
        textMuted: Color(0xFF726A92),
        gradient: [Color(0xFF8B7CF6), Color(0xFFC1B7FF)],
      );
  }
}

ThemeData buildFinanceTheme(AppThemeStyle style) {
  final palette = paletteForStyle(style);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.seed,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 31,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.35,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.3,
        color: palette.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: palette.textMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.cardTint,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: palette.cardTint,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border.withValues(alpha: 0.8),
      thickness: 0.7,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.cardTint.withValues(alpha: 0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.seed, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.seed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: palette.cardTint,
        foregroundColor: palette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: palette.cardBorderStrong),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.zero,
      iconColor: palette.textMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface.withValues(alpha: 0.92),
      indicatorColor: palette.surfaceAlt,
      height: 74,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? palette.seed : palette.textMuted,
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2F3640),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
