class ForecastSummary {
  const ForecastSummary({
    required this.averageMonthlyIncome,
    required this.averageMonthlyExpense,
    required this.averageMonthlySavings,
    required this.projectedSavingsInThreeMonths,
    required this.projectedSavingsInSixMonths,
  });

  final double averageMonthlyIncome;
  final double averageMonthlyExpense;
  final double averageMonthlySavings;
  final double projectedSavingsInThreeMonths;
  final double projectedSavingsInSixMonths;
}
