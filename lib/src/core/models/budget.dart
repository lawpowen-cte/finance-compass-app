class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.monthKey,
    required this.amount,
    this.currency = 'MYR',
    this.alertThreshold = 0.8,
    this.rolloverEnabled = false,
  });

  final String id;
  final String categoryId;
  final String monthKey;
  final double amount;
  final String currency;
  final double alertThreshold;
  final bool rolloverEnabled;
}
