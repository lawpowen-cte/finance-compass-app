import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart' hide Account, AssetSnapshot, Budget, Category;
import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/forecast_summary.dart';
import '../models/monthly_summary.dart';
import '../models/transaction.dart';
import 'sample_data.dart';

class FinanceRepository {
  FinanceRepository._({
    required this.database,
    required List<Account> accounts,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<FinanceTransaction> transactions,
    required List<AssetSnapshot> snapshots,
  })  : _accounts = accounts,
        _categories = categories,
        _budgets = budgets,
        _transactions = transactions,
        _snapshots = snapshots;

  final AppDatabase database;

  final List<Account> _accounts;
  final List<Category> _categories;
  final List<Budget> _budgets;
  final List<FinanceTransaction> _transactions;
  final List<AssetSnapshot> _snapshots;

  static FinanceRepository preview() {
    return FinanceRepository._(
      database: AppDatabase(),
      accounts: SampleData.accounts(),
      categories: SampleData.categories(),
      budgets: SampleData.budgets(),
      transactions: SampleData.transactions(),
      snapshots: SampleData.snapshots(),
    );
  }

  static Future<FinanceRepository> load(AppDatabase database) async {
    final accounts = await database.fetchAccounts();
    final categories = await database.fetchCategories();
    final budgets = await database.fetchBudgets();
    final transactions = await database.fetchTransactions();
    final snapshots = await database.fetchAssetSnapshots();

    return FinanceRepository._(
      database: database,
      accounts: accounts,
      categories: categories,
      budgets: budgets,
      transactions: transactions,
      snapshots: snapshots,
    );
  }

  Future<FinanceRepository> refresh() => FinanceRepository.load(database);

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);
  List<AssetSnapshot> get snapshots => List.unmodifiable(_snapshots);

  double totalAssetsByGroup(ReportGroup group) {
    return _accounts
        .where((account) => account.reportGroup == group)
        .fold(0, (sum, account) => sum + account.currentBalance);
  }

  double totalAssets({bool includeCredit = true}) {
    return _accounts
        .where((account) => includeCredit || account.reportGroup != ReportGroup.credit)
        .fold(0, (sum, account) => sum + account.currentBalance);
  }

  double expenseTotalForCategory(String categoryId, String monthKey) {
    return _transactions
        .where((transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.categoryId == categoryId &&
            _monthKey(transaction.transactionDate) == monthKey)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  Map<String, double> expenseBreakdownForAccount(String accountId, String monthKey) {
    final map = <String, double>{};

    for (final transaction in _transactions.where((item) =>
        item.accountId == accountId &&
        item.type == TransactionType.expense &&
        _monthKey(item.transactionDate) == monthKey)) {
      final key = transaction.categoryId ?? 'uncategorized';
      map[key] = (map[key] ?? 0) + transaction.amount;
    }

    return map;
  }

  String categoryName(String categoryId) {
    return _categories.firstWhere((item) => item.id == categoryId).name;
  }

  String accountName(String accountId) {
    return _accounts.firstWhere((item) => item.id == accountId).name;
  }

  List<Category> categoriesByType(CategoryType type) {
    return _categories.where((item) => item.type == type).toList();
  }

  List<Category> sortedCategories() {
    final items = [..._categories]
      ..sort((a, b) {
        final byType = a.type.name.compareTo(b.type.name);
        if (byType != 0) {
          return byType;
        }
        return a.name.compareTo(b.name);
      });
    return items;
  }

  List<Account> accountsByGroup(ReportGroup group) {
    return _accounts.where((item) => item.reportGroup == group).toList();
  }

  List<Account> investmentAccounts() {
    return _accounts.where((item) => item.reportGroup == ReportGroup.investment).toList();
  }

  List<FinanceTransaction> recentTransactions({int limit = 5}) {
    final items = [..._transactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return items.take(limit).toList();
  }

  List<FinanceTransaction> upcomingExpenseTransactions({int limit = 8}) {
    final now = DateTime.now();
    final items = _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.transactionDate.isAfter(DateTime(now.year, now.month, now.day)),
        )
        .toList()
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    return items.take(limit).toList();
  }

  double totalFutureExpense({int monthsAhead = 3}) {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month + monthsAhead, 1);
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.transactionDate.isAfter(DateTime(now.year, now.month, now.day - 1)) &&
              item.transactionDate.isBefore(lastDate),
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  List<MonthlySummary> futureExpenseSummaries({int months = 3}) {
    final now = DateTime.now();
    return List.generate(months, (index) {
      final date = DateTime(now.year, now.month + index + 1);
      final monthKey = _monthKey(date);
      return MonthlySummary(
        monthKey: monthKey,
        income: totalIncomeForMonth(monthKey),
        expense: totalExpenseForMonth(monthKey),
      );
    });
  }

  List<FinanceTransaction> transactionsForCategory(
    String categoryId, {
    String? monthKey,
  }) {
    final items = _transactions.where((item) => item.categoryId == categoryId);
    final filtered = monthKey == null
        ? items
        : items.where((item) => _monthKey(item.transactionDate) == monthKey);
    final list = filtered.toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  List<MonthlySummary> monthlySummaries({required int months}) {
    final monthKeys = _recentMonthKeys(months);
    return monthKeys
        .map(
          (monthKey) => MonthlySummary(
            monthKey: monthKey,
            income: totalIncomeForMonth(monthKey),
            expense: totalExpenseForMonth(monthKey),
          ),
        )
        .toList();
  }

  List<Budget> reusableBudgets() {
    final items = [..._budgets]
      ..sort((a, b) => categoryName(a.categoryId).compareTo(categoryName(b.categoryId)));
    return items;
  }

  List<Budget> activeBudgetsForMonth(String monthKey) {
    return _budgets.where((item) => _compareMonthKeys(item.monthKey, monthKey) <= 0).toList();
  }

  double totalBudgetAmount() {
    return _budgets.fold(0, (sum, item) => sum + item.amount);
  }

  double totalBudgetExpenseForMonth(String monthKey) {
    final budgetCategoryIds = activeBudgetsForMonth(monthKey).map((item) => item.categoryId).toSet();
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.categoryId != null &&
              budgetCategoryIds.contains(item.categoryId) &&
              _monthKey(item.transactionDate) == monthKey,
        )
        .fold(0, (sum, item) => sum + item.amount);
  }

  double effectiveBudgetForMonth(Budget budget, String monthKey) {
    if (_compareMonthKeys(monthKey, budget.monthKey) < 0) {
      return 0;
    }

    var carry = 0.0;
    for (final currentMonthKey in _monthKeyRange(budget.monthKey, monthKey)) {
      final effective = budget.amount + carry;
      if (currentMonthKey == monthKey) {
        return effective;
      }
      final spent = expenseTotalForCategory(budget.categoryId, currentMonthKey);
      carry = budget.rolloverEnabled ? (effective - spent).clamp(0, double.infinity) : 0.0;
    }
    return budget.amount;
  }

  double totalEffectiveBudgetForMonth(String monthKey) {
    return activeBudgetsForMonth(monthKey)
        .fold(0, (sum, item) => sum + effectiveBudgetForMonth(item, monthKey));
  }

  Map<String, double> categoryTotalsForMonths({
    required CategoryType type,
    required List<String> monthKeys,
  }) {
    final allowedIds = categoriesByType(type).map((item) => item.id).toSet();
    final totals = <String, double>{};
    for (final transaction in _transactions) {
      final categoryId = transaction.categoryId;
      if (categoryId == null || !allowedIds.contains(categoryId)) {
        continue;
      }
      if (!monthKeys.contains(_monthKey(transaction.transactionDate))) {
        continue;
      }
      if (type == CategoryType.expense && transaction.type != TransactionType.expense) {
        continue;
      }
      if (type == CategoryType.income && transaction.type != TransactionType.income) {
        continue;
      }
      totals[categoryId] = (totals[categoryId] ?? 0) + transaction.amount;
    }
    return totals;
  }

  ForecastSummary forecastSummary({int months = 3}) {
    final summaries = monthlySummaries(months: months);
    if (summaries.isEmpty) {
      return const ForecastSummary(
        averageMonthlyIncome: 0,
        averageMonthlyExpense: 0,
        averageMonthlySavings: 0,
        projectedSavingsInThreeMonths: 0,
        projectedSavingsInSixMonths: 0,
      );
    }

    final averageIncome =
        summaries.fold<double>(0, (sum, item) => sum + item.income) / summaries.length;
    final averageExpense =
        summaries.fold<double>(0, (sum, item) => sum + item.expense) / summaries.length;
    final averageSavings = averageIncome - averageExpense;
    final currentSavingsBase = totalAssetsByGroup(ReportGroup.cash) +
        totalAssetsByGroup(ReportGroup.investment) +
        totalAssetsByGroup(ReportGroup.retirement) +
        totalAssetsByGroup(ReportGroup.credit);

    return ForecastSummary(
      averageMonthlyIncome: averageIncome,
      averageMonthlyExpense: averageExpense,
      averageMonthlySavings: averageSavings,
      projectedSavingsInThreeMonths: currentSavingsBase + (averageSavings * 3),
      projectedSavingsInSixMonths: currentSavingsBase + (averageSavings * 6),
    );
  }

  double totalIncomeForMonth(String monthKey) {
    return _transactions
        .where((item) => item.type == TransactionType.income && _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double totalExpenseForMonth(String monthKey) {
    return _transactions
        .where((item) => item.type == TransactionType.expense && _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + item.amount);
  }

  Future<FinanceRepository> addAccount(Account account) async {
    await database.insertAccount(account);
    return refresh();
  }

  Future<FinanceRepository> updateExistingAccount(Account account) async {
    await database.updateAccount(account);
    return refresh();
  }

  Future<bool> canDeleteAccount(String accountId) {
    return database.accountHasLinkedData(accountId).then((hasLinks) => !hasLinks);
  }

  Future<FinanceRepository?> deleteAccountIfSafe(String accountId) async {
    final deleted = await database.deleteAccountIfSafe(accountId);
    if (!deleted) {
      return null;
    }
    return refresh();
  }

  Future<FinanceRepository> clearAllData() async {
    await database.clearAllUserData();
    return refresh();
  }

  Future<FinanceRepository> loadExampleData() async {
    await database.replaceAllWithSeedData(
      accountItems: SampleData.accounts(),
      categoryItems: SampleData.categories(),
      budgetItems: SampleData.budgets(),
      transactionItems: SampleData.transactions(),
      snapshotItems: SampleData.snapshots(),
    );
    return refresh();
  }

  Future<String> exportJsonSnapshot() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(p.join(directory.path, 'finance_compass_export_$timestamp.json'));
    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'accounts': _accounts
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'account_type': item.accountType.name,
              'report_group': item.reportGroup.name,
              'currency': item.currency,
              'initial_balance': item.initialBalance,
              'current_balance': item.currentBalance,
              'institution': item.institution,
              'note': item.note,
              'is_active': item.isActive,
            },
          )
          .toList(),
      'categories': _categories
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'type': item.type.name,
              'parent_id': item.parentId,
            },
          )
          .toList(),
      'budgets': _budgets
          .map(
            (item) => {
              'id': item.id,
              'category_id': item.categoryId,
              'month_key': item.monthKey,
              'amount': item.amount,
              'alert_threshold': item.alertThreshold,
              'rollover_enabled': item.rolloverEnabled,
            },
          )
          .toList(),
      'transactions': _transactions
          .map(
            (item) => {
              'id': item.id,
              'type': item.type.name,
              'account_id': item.accountId,
              'to_account_id': item.toAccountId,
              'category_id': item.categoryId,
              'amount': item.amount,
              'currency': item.currency,
              'transaction_date': item.transactionDate.toIso8601String(),
              'description': item.description,
              'merchant': item.merchant,
            },
          )
          .toList(),
      'asset_snapshots': _snapshots
          .map(
            (item) => {
              'id': item.id,
              'account_id': item.accountId,
              'snapshot_date': item.snapshotDate.toIso8601String(),
              'market_value': item.marketValue,
              'cost_basis': item.costBasis,
              'cash_balance': item.cashBalance,
              'unrealized_pnl': item.unrealizedPnl,
            },
          )
          .toList(),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<FinanceRepository> addCategory(Category category) async {
    await database.insertCategory(category);
    return refresh();
  }

  Future<FinanceRepository> updateExistingCategory(Category category) async {
    await database.updateCategory(category);
    return refresh();
  }

  Future<FinanceRepository> addBudget(Budget budget) async {
    await database.upsertBudget(budget);
    return refresh();
  }

  Future<FinanceRepository> deleteExistingBudget(String budgetId) async {
    await database.deleteBudget(budgetId);
    return refresh();
  }

  Future<FinanceRepository> addTransaction(FinanceTransaction transaction) async {
    await database.insertTransaction(transaction);
    return refresh();
  }

  Future<FinanceRepository> updateExistingTransaction(FinanceTransaction transaction) async {
    await database.updateTransaction(transaction);
    return refresh();
  }

  Future<FinanceRepository> deleteExistingTransaction(String transactionId) async {
    await database.deleteTransaction(transactionId);
    return refresh();
  }

  Future<FinanceRepository> addAssetSnapshot(AssetSnapshot snapshot) async {
    await database.insertAssetSnapshot(snapshot);
    return refresh();
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  int _compareMonthKeys(String left, String right) {
    final leftParts = left.split('-');
    final rightParts = right.split('-');
    if (leftParts.length != 2 || rightParts.length != 2) {
      return left.compareTo(right);
    }
    final leftYear = int.tryParse(leftParts[0]) ?? 0;
    final leftMonth = int.tryParse(leftParts[1]) ?? 0;
    final rightYear = int.tryParse(rightParts[0]) ?? 0;
    final rightMonth = int.tryParse(rightParts[1]) ?? 0;
    return DateTime(leftYear, leftMonth).compareTo(DateTime(rightYear, rightMonth));
  }

  List<String> _monthKeyRange(String startMonthKey, String endMonthKey) {
    final startParts = startMonthKey.split('-');
    final endParts = endMonthKey.split('-');
    if (startParts.length != 2 || endParts.length != 2) {
      return [endMonthKey];
    }
    final start = DateTime(int.parse(startParts[0]), int.parse(startParts[1]));
    final end = DateTime(int.parse(endParts[0]), int.parse(endParts[1]));
    final result = <String>[];
    var current = start;
    while (!current.isAfter(end)) {
      result.add(_monthKey(current));
      current = DateTime(current.year, current.month + 1);
    }
    return result;
  }

  List<String> _recentMonthKeys(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final date = DateTime(now.year, now.month - (count - index - 1));
      return _monthKey(date);
    });
  }
}
