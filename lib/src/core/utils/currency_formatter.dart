String formatMoney(double value, {String currency = 'MYR'}) {
  final sign = value < 0 ? '-' : '';
  return '$sign${currencyLabel(currency)} ${formatMoneyValue(value)}';
}

String formatMoneyValue(double value) {
  return value.abs().toStringAsFixed(2);
}

String currencyLabel(String currency) {
  return currency == 'MYR' ? 'RM' : currency;
}
