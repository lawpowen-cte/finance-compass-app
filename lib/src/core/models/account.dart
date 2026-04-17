enum AccountType {
  cash,
  bankSaving,
  eWallet,
  creditCard,
  moneyMarketFund,
  pension,
  stock,
  crypto,
  trading,
  fund,
  other,
}

enum ReportGroup {
  cash,
  credit,
  investment,
  retirement,
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.reportGroup,
    required this.currency,
    required this.currentBalance,
    this.institution,
    this.note,
    this.initialBalance = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final AccountType accountType;
  final ReportGroup reportGroup;
  final String currency;
  final double initialBalance;
  final double currentBalance;
  final String? institution;
  final String? note;
  final bool isActive;
}
