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
    required this.income,
    required this.expense,
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
  final Color income;
  final Color expense;
}

FinanceThemePalette paletteForStyle(AppThemeStyle style) {
  // Shared semantic colors — muted and gentle, not high-contrast.
  const incomeColor = Color(0xFF7BAE8A);   // soft sage green
  const expenseColor = Color(0xFFD49A9A);  // soft dusty rose

  switch (style) {
    case AppThemeStyle.tide:
      return const FinanceThemePalette(
        seed: Color(0xFF6A9E95),
        background: Color(0xFFF6F8FA),
        backgroundTop: Color(0xFFFAFBFC),
        backgroundBottom: Color(0xFFF1F4F7),
        surface: Color(0xFFFCFDFE),
        surfaceAlt: Color(0xFFEEF2F6),
        border: Color(0xFFE2E7ED),
        cardTint: Color(0xFFEFF5F3),
        cardBorderStrong: Color(0xFFB8D4CE),
        textPrimary: Color(0xFF3D6058),
        textMuted: Color(0xFF8A939B),
        gradient: [Color(0xFFA8D5CC), Color(0xFFE2EDE9)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.ocean:
      return const FinanceThemePalette(
        seed: Color(0xFF5A9EB5),
        background: Color(0xFFF3F7FA),
        backgroundTop: Color(0xFFF8FBFD),
        backgroundBottom: Color(0xFFEAF0F5),
        surface: Color(0xFFFBFCFE),
        surfaceAlt: Color(0xFFE8EFF5),
        border: Color(0xFFD8E2EA),
        cardTint: Color(0xFFEAF3F8),
        cardBorderStrong: Color(0xFFA3C9DA),
        textPrimary: Color(0xFF3A6A7E),
        textMuted: Color(0xFF8496A2),
        gradient: [Color(0xFF7BB8D4), Color(0xFFD0E6F0)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.sky:
      return const FinanceThemePalette(
        seed: Color(0xFF7A9FD0),
        background: Color(0xFFF4F6FB),
        backgroundTop: Color(0xFFFAFBFE),
        backgroundBottom: Color(0xFFECF0F8),
        surface: Color(0xFFFCFDFF),
        surfaceAlt: Color(0xFFEDF1F9),
        border: Color(0xFFDAE2EF),
        cardTint: Color(0xFFECF1FC),
        cardBorderStrong: Color(0xFFB0C6E4),
        textPrimary: Color(0xFF446387),
        textMuted: Color(0xFF8490A4),
        gradient: [Color(0xFF9FC4F0), Color(0xFFDAE6F8)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.ember:
      return const FinanceThemePalette(
        seed: Color(0xFFC49070),
        background: Color(0xFFF8F6F5),
        backgroundTop: Color(0xFFFCFAF9),
        backgroundBottom: Color(0xFFF3EEEB),
        surface: Color(0xFFFEFDFC),
        surfaceAlt: Color(0xFFF5EDE6),
        border: Color(0xFFEBE0D9),
        cardTint: Color(0xFFF8EDE5),
        cardBorderStrong: Color(0xFFDDBAA0),
        textPrimary: Color(0xFF7A5E48),
        textMuted: Color(0xFF948478),
        gradient: [Color(0xFFF0D0BA), Color(0xFFF8EBE0)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.forest:
      return const FinanceThemePalette(
        seed: Color(0xFF8BA480),
        background: Color(0xFFF5F7F3),
        backgroundTop: Color(0xFFFAFBF8),
        backgroundBottom: Color(0xFFEFF3EB),
        surface: Color(0xFFFDFFFC),
        surfaceAlt: Color(0xFFEFF3E9),
        border: Color(0xFFDFE5DA),
        cardTint: Color(0xFFEFF5EA),
        cardBorderStrong: Color(0xFFB8CBAD),
        textPrimary: Color(0xFF4D6643),
        textMuted: Color(0xFF8A9282),
        gradient: [Color(0xFFC0D4B2), Color(0xFFE4ECD9)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.dune:
      return const FinanceThemePalette(
        seed: Color(0xFFC4966A),
        background: Color(0xFFFAF5EF),
        backgroundTop: Color(0xFFFDFAF6),
        backgroundBottom: Color(0xFFF4E8DB),
        surface: Color(0xFFFFFDF9),
        surfaceAlt: Color(0xFFF5EADD),
        border: Color(0xFFEDE0D2),
        cardTint: Color(0xFFF8ECE0),
        cardBorderStrong: Color(0xFFDABB96),
        textPrimary: Color(0xFF7A5C3E),
        textMuted: Color(0xFF9A8575),
        gradient: [Color(0xFFE8C8A0), Color(0xFFF5E8D6)],
        income: incomeColor,
        expense: expenseColor,
      );
    case AppThemeStyle.aurora:
      return const FinanceThemePalette(
        seed: Color(0xFF8C7EC8),
        background: Color(0xFFF5F3FA),
        backgroundTop: Color(0xFFFAF9FE),
        backgroundBottom: Color(0xFFEEEAF6),
        surface: Color(0xFFFEFDFF),
        surfaceAlt: Color(0xFFF0EDF9),
        border: Color(0xFFE0DDF2),
        cardTint: Color(0xFFF0EDFC),
        cardBorderStrong: Color(0xFFBEB4E4),
        textPrimary: Color(0xFF5C5098),
        textMuted: Color(0xFF908AA4),
        gradient: [Color(0xFFA89EED), Color(0xFFD4CFFF)],
        income: incomeColor,
        expense: expenseColor,
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
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: palette.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: palette.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: palette.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: palette.textMuted,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: palette.textMuted,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.cardTint,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: palette.cardTint,
          width: 0.5,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: palette.border.withValues(alpha: 0.5),
      thickness: 0.5,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceAlt.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.seed, width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.seed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        elevation: 0,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        backgroundColor: palette.surfaceAlt.withValues(alpha: 0.5),
        foregroundColor: palette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: palette.border, width: 0.5),
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
      backgroundColor: palette.textPrimary.withValues(alpha: 0.88),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
