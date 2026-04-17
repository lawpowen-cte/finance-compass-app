import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class SampleData {
  static List<Account> accounts() {
    return const [
      Account(
        id: 'acc_cash_wallet',
        name: 'Wallet Cash',
        accountType: AccountType.cash,
        reportGroup: ReportGroup.cash,
        currency: 'MYR',
        currentBalance: 420,
      ),
      Account(
        id: 'acc_tng',
        name: 'Touch n Go eWallet',
        accountType: AccountType.eWallet,
        reportGroup: ReportGroup.cash,
        currency: 'MYR',
        currentBalance: 860,
      ),
      Account(
        id: 'acc_maybank',
        name: 'Maybank Savings',
        accountType: AccountType.bankSaving,
        reportGroup: ReportGroup.cash,
        currency: 'MYR',
        currentBalance: 12850,
      ),
      Account(
        id: 'acc_card',
        name: 'Visa Credit Card',
        accountType: AccountType.creditCard,
        reportGroup: ReportGroup.credit,
        currency: 'MYR',
        currentBalance: -2310,
      ),
      Account(
        id: 'acc_mmf',
        name: 'Money Market Fund',
        accountType: AccountType.moneyMarketFund,
        reportGroup: ReportGroup.investment,
        currency: 'MYR',
        currentBalance: 16000,
      ),
      Account(
        id: 'acc_trading',
        name: 'Trading Account',
        accountType: AccountType.trading,
        reportGroup: ReportGroup.investment,
        currency: 'USD',
        currentBalance: 4800,
      ),
      Account(
        id: 'acc_crypto',
        name: 'Crypto Wallet',
        accountType: AccountType.crypto,
        reportGroup: ReportGroup.investment,
        currency: 'USD',
        currentBalance: 1100,
      ),
      Account(
        id: 'acc_pension',
        name: 'Pension Account',
        accountType: AccountType.pension,
        reportGroup: ReportGroup.retirement,
        currency: 'MYR',
        currentBalance: 45200,
      ),
    ];
  }

  static List<Category> categories() {
    return const [
      Category(id: 'cat_salary', name: 'Salary', type: CategoryType.income),
      Category(id: 'cat_food', name: 'Food', type: CategoryType.expense),
      Category(id: 'cat_transport', name: 'Transport', type: CategoryType.expense),
      Category(id: 'cat_housing', name: 'Housing', type: CategoryType.expense),
      Category(id: 'cat_shopping', name: 'Shopping', type: CategoryType.expense),
      Category(id: 'cat_invest', name: 'Investment Top-up', type: CategoryType.investment),
      Category(id: 'cat_transfer', name: 'Account Transfer', type: CategoryType.transfer),
    ];
  }

  static List<Budget> budgets() {
    return const [
      Budget(id: 'budget_food', categoryId: 'cat_food', monthKey: '2026-04', amount: 1200),
      Budget(id: 'budget_transport', categoryId: 'cat_transport', monthKey: '2026-04', amount: 500),
      Budget(id: 'budget_housing', categoryId: 'cat_housing', monthKey: '2026-04', amount: 1800),
      Budget(id: 'budget_shopping', categoryId: 'cat_shopping', monthKey: '2026-04', amount: 600),
    ];
  }

  static List<FinanceTransaction> transactions() {
    return [
      FinanceTransaction(
        id: 'txn_1',
        type: TransactionType.income,
        accountId: 'acc_maybank',
        categoryId: 'cat_salary',
        amount: 8500,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 1),
        description: 'Monthly salary',
      ),
      FinanceTransaction(
        id: 'txn_2',
        type: TransactionType.expense,
        accountId: 'acc_tng',
        categoryId: 'cat_food',
        amount: 38,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 3),
        merchant: 'Lunch',
      ),
      FinanceTransaction(
        id: 'txn_3',
        type: TransactionType.expense,
        accountId: 'acc_card',
        categoryId: 'cat_shopping',
        amount: 420,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 7),
        merchant: 'Online store',
      ),
      FinanceTransaction(
        id: 'txn_4',
        type: TransactionType.expense,
        accountId: 'acc_maybank',
        categoryId: 'cat_housing',
        amount: 1500,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 5),
        merchant: 'Rent',
      ),
      FinanceTransaction(
        id: 'txn_5',
        type: TransactionType.transfer,
        accountId: 'acc_maybank',
        toAccountId: 'acc_trading',
        categoryId: 'cat_transfer',
        amount: 1000,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 9),
        description: 'Transfer to trading account',
      ),
      FinanceTransaction(
        id: 'txn_6',
        type: TransactionType.expense,
        accountId: 'acc_tng',
        categoryId: 'cat_transport',
        amount: 210,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 12),
        merchant: 'Ride hailing',
      ),
      FinanceTransaction(
        id: 'txn_7',
        type: TransactionType.expense,
        accountId: 'acc_tng',
        categoryId: 'cat_food',
        amount: 980,
        currency: 'MYR',
        transactionDate: DateTime(2026, 4, 13),
        merchant: 'Groceries and dining',
      ),
    ];
  }

  static List<AssetSnapshot> snapshots() {
    return [
      AssetSnapshot(
        id: 'snap_mmf',
        accountId: 'acc_mmf',
        snapshotDate: DateTime(2026, 4, 15),
        marketValue: 16000,
        costBasis: 15450,
        unrealizedPnl: 550,
      ),
      AssetSnapshot(
        id: 'snap_trade',
        accountId: 'acc_trading',
        snapshotDate: DateTime(2026, 4, 15),
        marketValue: 4800,
        costBasis: 4500,
        cashBalance: 400,
        unrealizedPnl: 300,
      ),
      AssetSnapshot(
        id: 'snap_crypto',
        accountId: 'acc_crypto',
        snapshotDate: DateTime(2026, 4, 15),
        marketValue: 1100,
        costBasis: 900,
        unrealizedPnl: 200,
      ),
      AssetSnapshot(
        id: 'snap_pension',
        accountId: 'acc_pension',
        snapshotDate: DateTime(2026, 4, 15),
        marketValue: 45200,
        costBasis: 40000,
        unrealizedPnl: 5200,
      ),
    ];
  }
}
