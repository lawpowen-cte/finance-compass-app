enum TransactionType {
  income,
  expense,
  transfer,
  adjustment,
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    this.categoryId,
    this.toAccountId,
    this.description,
    this.merchant,
  });

  final String id;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final DateTime transactionDate;
  final String? description;
  final String? merchant;
}
