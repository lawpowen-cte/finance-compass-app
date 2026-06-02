enum TransactionType {
  income,
  expense,
  transfer,
  adjustment,
}

enum TransactionStatus {
  planned,
  actual,
  settled,
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    DateTime? recordDate,
    this.status = TransactionStatus.actual,
    this.recurringRuleId,
    this.categoryId,
    this.toAccountId,
    this.toAmount,
    this.toCurrency,
    this.description,
    this.merchant,
  }) : recordDate = recordDate ?? transactionDate;

  final String id;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final double? toAmount;
  final String? toCurrency;
  final DateTime recordDate;
  final DateTime transactionDate;
  final TransactionStatus status;
  final String? recurringRuleId;
  final String? description;
  final String? merchant;

  bool get affectsBalance => status != TransactionStatus.planned;

  double get transferInAmount => toAmount ?? amount;

  String get transferInCurrency => toCurrency ?? currency;
}
