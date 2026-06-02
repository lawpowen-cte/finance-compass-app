import 'package:finance_app/src/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats supported currencies with user-facing labels', () {
    expect(formatMoney(12.5, currency: 'MYR'), 'RM 12.50');
    expect(formatMoney(12.5, currency: 'USD'), 'US\$ 12.50');
    expect(formatMoney(12.5, currency: 'CNY'), 'RMB 12.50');
    expect(formatMoney(12.5, currency: 'TWD'), 'NT\$ 12.50');
  });

  test('normalizes unsupported currency to MYR', () {
    expect(normalizeCurrency('usd'), 'USD');
    expect(normalizeCurrency('SGD'), 'MYR');
  });

  test('converts between account currencies through MYR base rates', () {
    final rates = normalizedExchangeRatesToBase({
      'MYR': 1,
      'TWD': 0.15,
      'USD': 4.5,
    });

    expect(
      convertCurrencyAmount(
        amount: 150,
        fromCurrency: 'MYR',
        toCurrency: 'TWD',
        ratesToBase: rates,
      ),
      1000,
    );
    expect(
      convertCurrencyAmount(
        amount: 1000,
        fromCurrency: 'TWD',
        toCurrency: 'MYR',
        ratesToBase: rates,
      ),
      150,
    );
  });

  test('uses selected base currency for default money display', () {
    setActiveBaseCurrency('TWD');
    expect(formatMoney(12.5), 'NT\$ 12.50');

    setActiveBaseCurrency('MYR');
    expect(formatMoney(12.5), 'RM 12.50');
  });
}
