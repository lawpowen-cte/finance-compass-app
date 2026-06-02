import 'package:finance_app/src/core/data/finance_repository.dart';
import 'package:finance_app/src/core/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recurring rule creates planned transaction drafts with rule id', () {
    final base = FinanceTransaction(
      id: 'txn_salary',
      type: TransactionType.income,
      accountId: 'acc_bank',
      amount: 3000,
      currency: 'MYR',
      transactionDate: DateTime(2026, 4, 28),
      status: TransactionStatus.actual,
      description: 'Salary',
    );
    final rule = RecurringTransactionRule.fromTransaction(
      id: 'rule_salary',
      name: '工资',
      transaction: base,
    );
    final generated = rule.toTransaction(
      id: 'txn_salary_2026_05',
      date: DateTime(2026, 5, 28),
      status: TransactionStatus.planned,
    );

    expect(generated.recurringRuleId, 'rule_salary');
    expect(generated.status, TransactionStatus.planned);
    expect(generated.amount, 3000);
    expect(generated.description, 'Salary');
  });

  test('recurring rule preserves cross-currency transfer amounts', () {
    final base = FinanceTransaction(
      id: 'txn_transfer',
      type: TransactionType.transfer,
      accountId: 'acc_myr',
      toAccountId: 'acc_twd',
      amount: 150,
      currency: 'MYR',
      toAmount: 1000,
      toCurrency: 'TWD',
      transactionDate: DateTime(2026, 4, 28),
      status: TransactionStatus.actual,
    );
    final rule = RecurringTransactionRule.fromTransaction(
      id: 'rule_transfer',
      name: 'FX transfer',
      transaction: base,
    );

    final generated = rule.toTransaction(
      id: 'txn_transfer_2026_05',
      date: DateTime(2026, 5, 28),
      status: TransactionStatus.planned,
    );

    expect(generated.amount, 150);
    expect(generated.currency, 'MYR');
    expect(generated.toAmount, 1000);
    expect(generated.toCurrency, 'TWD');
    expect(generated.transferInAmount, 1000);
    expect(generated.transferInCurrency, 'TWD');
  });
}
