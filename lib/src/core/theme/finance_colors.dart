import 'package:flutter/material.dart';

/// Unified color constants for Finance Compass
/// Use these constants across all screens for consistent visual language

class FinanceColors {
  FinanceColors._();

  // ── Income / Positive ──
  static const Color income = Color(0xFF15803D);
  static const Color incomeSoft = Color(0xFF6AAF8A);

  // ── Expense / Negative ──
  static const Color expense = Color(0xFFB91C1C);
  static const Color expenseSoft = Color(0xFFE07B7B);

  // ── Budget Thresholds ──
  static const Color budgetSafe = Color(0xFF15803D);
  static const Color budgetWarning = Color(0xFFEA580C);
  static const Color budgetOver = Color(0xFFB91C1C);

  // ── Neutral / Info ──
  static const Color info = Color(0xFF5B9BD5);
  static const Color transfer = Color(0xFF475569);
  static const Color adjustment = Color(0xFF0369A1);

  // ── Status ──
  static const Color planned = Color(0xFFB45309);
  static const Color success = Color(0xFF15803D);

  // ── Asset Groups ──
  static const Color cash = Color(0xFF5B9BD5);
  static const Color credit = Color(0xFFE07B7B);
  static const Color investment = Color(0xFF6AAF8A);
  static const Color retirement = Color(0xFFE8A838);

  // ── Category Breakdown ──
  static const List<Color> categoryPalette = [
    Color(0xFF5B9BD5),
    Color(0xFF6AAF8A),
    Color(0xFFE8A838),
    Color(0xFFE07B7B),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE67E22),
    Color(0xFF3498DB),
  ];
}