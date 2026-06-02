const baseCurrencyCode = 'MYR';
const supportedCurrencies = ['MYR', 'USD', 'CNY', 'TWD'];
String activeBaseCurrencyCode = baseCurrencyCode;

const defaultExchangeRatesToBase = <String, double>{
  'MYR': 1,
  'USD': 4.7,
  'CNY': 0.65,
  'TWD': 0.14,
};

void setActiveBaseCurrency(String currency) {
  activeBaseCurrencyCode = normalizeCurrency(currency);
}

String formatMoney(double value, {String? currency}) {
  final displayCurrency = normalizeCurrency(currency ?? activeBaseCurrencyCode);
  final sign = value < 0 ? '-' : '';
  return '$sign${currencyLabel(displayCurrency)} ${formatMoneyValue(value)}';
}

String formatMoneyValue(double value) {
  return value.abs().toStringAsFixed(2);
}

String currencyLabel(String currency) {
  switch (normalizeCurrency(currency)) {
    case 'MYR':
      return 'RM';
    case 'USD':
      return 'US\$';
    case 'CNY':
      return 'RMB';
    case 'TWD':
      return 'NT\$';
    default:
      return currency.toUpperCase();
  }
}

String currencyOptionLabel(String currency) {
  final normalized = normalizeCurrency(currency);
  return '$normalized (${currencyLabel(normalized)})';
}

String normalizeCurrency(String currency) {
  final normalized = currency.trim().toUpperCase();
  return supportedCurrencies.contains(normalized)
      ? normalized
      : baseCurrencyCode;
}

Map<String, double> normalizedExchangeRatesToBase(
  Map<String, double>? rates, {
  String baseCurrency = baseCurrencyCode,
}) {
  final base = normalizeCurrency(baseCurrency);
  return {
    for (final currency in supportedCurrencies)
      currency: currency == base
          ? 1
          : _safeRate(rates?[currency] ?? defaultExchangeRatesToBase[currency]),
  };
}

double exchangeRateToBase(
  String currency,
  Map<String, double> ratesToBase, {
  String baseCurrency = baseCurrencyCode,
}) {
  final normalized = normalizeCurrency(currency);
  if (normalized == normalizeCurrency(baseCurrency)) {
    return 1;
  }
  return _safeRate(ratesToBase[normalized]);
}

double convertCurrencyAmount({
  required double amount,
  required String fromCurrency,
  required String toCurrency,
  required Map<String, double> ratesToBase,
  String baseCurrency = baseCurrencyCode,
}) {
  final fromRate = exchangeRateToBase(
    fromCurrency,
    ratesToBase,
    baseCurrency: baseCurrency,
  );
  final toRate = exchangeRateToBase(
    toCurrency,
    ratesToBase,
    baseCurrency: baseCurrency,
  );
  return amount * fromRate / toRate;
}

String formatConversionHint({
  required double amount,
  required String fromCurrency,
  required String toCurrency,
  required Map<String, double> ratesToBase,
  String baseCurrency = baseCurrencyCode,
}) {
  final converted = convertCurrencyAmount(
    amount: amount,
    fromCurrency: fromCurrency,
    toCurrency: toCurrency,
    ratesToBase: ratesToBase,
    baseCurrency: baseCurrency,
  );
  return '≈ ${formatMoney(converted, currency: toCurrency)}';
}

double _safeRate(double? rate) {
  if (rate == null || rate <= 0 || rate.isNaN || rate.isInfinite) {
    return 1;
  }
  return rate;
}
