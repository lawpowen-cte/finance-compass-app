String formatMoney(double value, {String currency = 'MYR'}) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs().toStringAsFixed(2);
  final displayCurrency = currency == 'MYR' ? 'RM' : currency;
  return '$sign$displayCurrency $absolute';
}
