import 'package:finance_app/src/core/data/finance_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account balance trace matches accountBalanceAt for every account', () {
    final repository = FinanceRepository.preview();
    final cutoffDate = DateTime(2026, 4, 30, 23, 59, 59, 999);

    for (final account in repository.accounts) {
      final trace = repository.accountBalanceTrace(account.id, cutoffDate);
      final balance = repository.accountBalanceAt(account.id, cutoffDate);

      expect(
        trace.endingBalance,
        closeTo(balance, 0.001),
        reason: '${account.name} trace should explain the displayed balance.',
      );
    }
  });
}
