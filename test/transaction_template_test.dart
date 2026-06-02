import 'package:finance_app/src/core/data/finance_repository.dart';
import 'package:finance_app/src/core/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transaction template preserves reusable transaction fields', () {
    final transaction = FinanceTransaction(
      id: 'txn_1',
      type: TransactionType.transfer,
      accountId: 'acc_cash',
      toAccountId: 'acc_invest',
      categoryId: 'cat_transfer',
      amount: 500,
      currency: 'MYR',
      toAmount: 3333.33,
      toCurrency: 'TWD',
      recordDate: DateTime(2026, 4, 1),
      transactionDate: DateTime(2026, 4, 2),
      status: TransactionStatus.planned,
      description: 'Monthly investment',
      merchant: 'Broker',
    );

    final template = TransactionTemplate.fromTransaction(
      id: 'tpl_1',
      name: '投资定投',
      transaction: transaction,
    );
    final restored = TransactionTemplate.fromJson(template.toJson());

    expect(restored.name, '投资定投');
    expect(restored.type, TransactionType.transfer);
    expect(restored.accountId, 'acc_cash');
    expect(restored.toAccountId, 'acc_invest');
    expect(restored.categoryId, 'cat_transfer');
    expect(restored.amount, 500);
    expect(restored.currency, 'MYR');
    expect(restored.toAmount, 3333.33);
    expect(restored.toCurrency, 'TWD');
    expect(restored.status, TransactionStatus.planned);
    expect(restored.description, 'Monthly investment');
    expect(restored.merchant, 'Broker');
  });
}
