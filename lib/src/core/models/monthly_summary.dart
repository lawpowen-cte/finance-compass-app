class MonthlySummary {
  const MonthlySummary({
    required this.monthKey,
    required this.income,
    required this.expense,
  });

  final String monthKey;
  final double income;
  final double expense;

  double get net => income - expense;
}
