import 'package:finance_app/src/core/models/transaction.dart';
import 'package:finance_app/src/features/transactions/transaction_form_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildRecurringTransactions creates monthly records with unique ids', () {
    final baseTransaction = FinanceTransaction(
      id: 'txn_seed',
      type: TransactionType.expense,
      accountId: 'acc_1',
      amount: 120,
      currency: 'MYR',
      transactionDate: DateTime(2026, 4, 22),
      categoryId: 'cat_1',
      description: 'Rent',
      merchant: 'Landlord',
    );

    final transactions = buildRecurringTransactions(
      baseTransaction: baseTransaction,
      months: 6,
    );

    expect(transactions, hasLength(6));
    expect(
      transactions.map((item) => item.id).toSet(),
      hasLength(6),
    );
    expect(
      transactions.map((item) => item.transactionDate.month).toList(),
      [4, 5, 6, 7, 8, 9],
    );
    expect(transactions.first.transactionDate, DateTime(2026, 4, 22));
    expect(transactions.last.transactionDate, DateTime(2026, 9, 22));
  });
}
