import 'package:finance_app/src/core/data/finance_repository.dart';
import 'package:finance_app/src/core/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cross-currency transfer uses source and target amounts separately', () {
    final repository = FinanceRepository.preview();
    final transfer = FinanceTransaction(
      id: 'txn_fx',
      type: TransactionType.transfer,
      accountId: 'acc_myr',
      toAccountId: 'acc_twd',
      amount: 150,
      currency: 'MYR',
      toAmount: 1000,
      toCurrency: 'TWD',
      transactionDate: DateTime(2026, 5, 1),
    );

    expect(repository.transactionDeltaForAccount('acc_myr', transfer), -150);
    expect(repository.transactionDeltaForAccount('acc_twd', transfer), 1000);
    expect(
      repository.convertAmount(
        amount: 1000,
        fromCurrency: 'TWD',
        toCurrency: 'MYR',
      ),
      140,
    );
  });
}
