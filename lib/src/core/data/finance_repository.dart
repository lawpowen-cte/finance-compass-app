import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
import '../utils/month_key.dart';
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
    return _accounts
        .where(
          (item) =>
              item.reportGroup == ReportGroup.investment || item.reportGroup == ReportGroup.retirement,
        )
        .toList();
  }

  AssetSnapshot? latestSnapshotForAccount(String accountId) {
    final items = _snapshots.where((item) => item.accountId == accountId).toList()
      ..sort((a, b) => b.snapshotDate.compareTo(a.snapshotDate));
    return items.isEmpty ? null : items.first;
  }

  List<AssetSnapshot> snapshotsForAccount(String accountId) {
    final items = _snapshots.where((item) => item.accountId == accountId).toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    return items;
  }

  AssetSnapshot? firstSnapshotForAccount(String accountId) {
    final items = snapshotsForAccount(accountId);
    return items.isEmpty ? null : items.first;
  }

  double costBasisForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final firstSnapshot = firstSnapshotForAccount(accountId);
    if (firstSnapshot == null) {
      return investmentFlowSummaryForAccount(
        accountId,
        upToDate: upToDate,
      ).contribution;
    }

    if (upToDate != null && upToDate.isBefore(firstSnapshot.snapshotDate)) {
      return firstSnapshot.costBasis;
    }

    final deltaFlow = investmentFlowSummaryForAccount(
      accountId,
      fromDateExclusive: firstSnapshot.snapshotDate,
      upToDate: upToDate,
    );
    return (firstSnapshot.costBasis + deltaFlow.contribution).clamp(0, double.infinity).toDouble();
  }

  double snapshotCostBasis(AssetSnapshot snapshot) {
    return costBasisForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
  }

  double remainingCostBasisForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final cumulativeCost = costBasisForAccount(
      accountId,
      upToDate: upToDate,
    );
    final flow = investmentFlowSummaryForAccount(
      accountId,
      upToDate: upToDate,
    );
    return (cumulativeCost - flow.withdrawal).clamp(0, double.infinity).toDouble();
  }

  double snapshotRemainingCostBasis(AssetSnapshot snapshot) {
    return remainingCostBasisForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
  }

  double snapshotUnrealizedPnl(AssetSnapshot snapshot) {
    return snapshot.marketValue - snapshotRemainingCostBasis(snapshot);
  }

  double snapshotPnlRatio(AssetSnapshot snapshot) {
    final costBasis = snapshotRemainingCostBasis(snapshot);
    if (costBasis == 0) {
      return 0;
    }
    return snapshotUnrealizedPnl(snapshot) / costBasis;
  }

  InvestmentFlowSummary investmentFlowSummaryForAccount(
    String accountId, {
    DateTime? fromDateExclusive,
    DateTime? upToDate,
  }) {
    double contribution = 0;
    double withdrawal = 0;

    for (final transaction in _transactions) {
      if (fromDateExclusive != null &&
          !transaction.transactionDate.isAfter(fromDateExclusive)) {
        continue;
      }
      if (upToDate != null && transaction.transactionDate.isAfter(upToDate)) {
        continue;
      }

      if (transaction.type == TransactionType.transfer) {
        if (transaction.toAccountId == accountId) {
          contribution += transaction.amount;
        }
        if (transaction.accountId == accountId) {
          withdrawal += transaction.amount;
        }
      }

      if (transaction.type == TransactionType.adjustment &&
          transaction.accountId == accountId) {
        if (transaction.amount >= 0) {
          contribution += transaction.amount;
        } else {
          withdrawal += transaction.amount.abs();
        }
      }
    }

    return InvestmentFlowSummary(
      contribution: contribution,
      withdrawal: withdrawal,
    );
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
      ..sort((a, b) {
        final categoryCompare = categoryName(a.categoryId).compareTo(categoryName(b.categoryId));
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        return _compareMonthKeys(b.monthKey, a.monthKey);
      });
    return items;
  }

  List<Budget> activeBudgetsForMonth(String monthKey) {
    final latestByCategory = <String, Budget>{};
    for (final budget in _budgets) {
      if (_compareMonthKeys(budget.monthKey, monthKey) > 0) {
        continue;
      }
      final existing = latestByCategory[budget.categoryId];
      if (existing == null || _compareMonthKeys(budget.monthKey, existing.monthKey) > 0) {
        latestByCategory[budget.categoryId] = budget;
      }
    }
    final items = latestByCategory.values.toList()
      ..sort((a, b) => categoryName(a.categoryId).compareTo(categoryName(b.categoryId)));
    return items;
  }

  List<String> budgetMonthKeys({int futureMonths = 6}) {
    final now = DateTime.now();
    final monthKeys = <String>{
      monthKeyFromDate(now),
      ..._transactions.map((item) => monthKeyFromDate(item.transactionDate)),
      ..._budgets.map((item) => item.monthKey),
      ...List.generate(futureMonths, (index) => monthKeyFromDate(DateTime(now.year, now.month + index + 1))),
    }.toList()
      ..sort((a, b) => _compareMonthKeys(b, a));
    return monthKeys;
  }

  double totalBudgetAmount({String? monthKey}) {
    final items = monthKey == null ? _budgets : activeBudgetsForMonth(monthKey);
    return items.fold(0, (sum, item) => sum + item.amount);
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

    final categoryBudgets = _budgets
        .where((item) => item.categoryId == budget.categoryId)
        .toList()
      ..sort((a, b) => _compareMonthKeys(a.monthKey, b.monthKey));
    if (categoryBudgets.isEmpty) {
      return 0;
    }

    final firstBudget = categoryBudgets.first;
    var carry = 0.0;
    for (final currentMonthKey in _monthKeyRange(firstBudget.monthKey, monthKey)) {
      final activeBudget = _budgetForCategoryInMonth(budget.categoryId, currentMonthKey);
      if (activeBudget == null) {
        carry = 0.0;
        continue;
      }
      final effective = activeBudget.amount + carry;
      if (currentMonthKey == monthKey) {
        return effective;
      }
      final spent = expenseTotalForCategory(activeBudget.categoryId, currentMonthKey);
      carry = activeBudget.rolloverEnabled ? (effective - spent).clamp(0, double.infinity) : 0.0;
    }
    return 0;
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
    final summaries = monthlySummaries(months: 12)
        .where((item) => item.income != 0 || item.expense != 0)
        .take(months)
        .toList();
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

  Future<Map<String, dynamic>> buildJsonSnapshotPayload() async {
    final metaValues = await database.fetchAllMetaValues();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'meta': metaValues,
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
  }

  Future<Uint8List> exportJsonSnapshotBytes() async {
    final payload = await buildJsonSnapshotPayload();
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  Future<String> exportJsonSnapshot([String? targetPath]) async {
    final file = File(targetPath ?? await _defaultExportPath());
    final payload = await buildJsonSnapshotPayload();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Map<String, dynamic> buildAiSummaryPayload({required List<String> monthKeys}) {
    final includedMonths = monthKeys.where((monthKey) {
      return totalIncomeForMonth(monthKey) != 0 || totalExpenseForMonth(monthKey) != 0;
    }).toList();
    final currentMonth = monthKeyFromDate(DateTime.now());
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'months': includedMonths,
      'income_by_month': {
        for (final monthKey in includedMonths) monthKey: totalIncomeForMonth(monthKey),
      },
      'expense_by_month': {
        for (final monthKey in includedMonths) monthKey: totalExpenseForMonth(monthKey),
      },
      'net_by_month': {
        for (final monthKey in includedMonths)
          monthKey: totalIncomeForMonth(monthKey) - totalExpenseForMonth(monthKey),
      },
      'expense_categories_by_month': {
        for (final monthKey in includedMonths)
          monthKey: {
            for (final entry in categoryTotalsForMonths(
              type: CategoryType.expense,
              monthKeys: [monthKey],
            ).entries)
              categoryName(entry.key): entry.value,
          },
      },
      'income_categories_by_month': {
        for (final monthKey in includedMonths)
          monthKey: {
            for (final entry in categoryTotalsForMonths(
              type: CategoryType.income,
              monthKeys: [monthKey],
            ).entries)
              categoryName(entry.key): entry.value,
          },
      },
      'expense_category_totals': {
        for (final entry in categoryTotalsForMonths(
          type: CategoryType.expense,
          monthKeys: includedMonths,
        ).entries)
          categoryName(entry.key): entry.value,
      },
      'income_category_totals': {
        for (final entry in categoryTotalsForMonths(
          type: CategoryType.income,
          monthKeys: includedMonths,
        ).entries)
          categoryName(entry.key): entry.value,
      },
      'assets_by_group': {
        'cash': totalAssetsByGroup(ReportGroup.cash),
        'credit': totalAssetsByGroup(ReportGroup.credit),
        'investment': totalAssetsByGroup(ReportGroup.investment),
        'retirement': totalAssetsByGroup(ReportGroup.retirement),
      },
      'budgets_current_month': {
        for (final budget in activeBudgetsForMonth(currentMonth))
          categoryName(budget.categoryId): {
            'budget': effectiveBudgetForMonth(budget, currentMonth),
            'spent': expenseTotalForCategory(budget.categoryId, currentMonth),
          },
      },
    };
  }

  Uint8List exportAiSummaryBytes({required List<String> monthKeys}) {
    return Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(
          buildAiSummaryPayload(monthKeys: monthKeys),
        ),
      ),
    );
  }

  Future<String> exportAiSummaryJson(String targetPath, {required List<String> monthKeys}) async {
    final payload = buildAiSummaryPayload(monthKeys: monthKeys);
    final file = File(targetPath);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<FinanceRepository> importJsonSnapshot(String path) async {
    final file = File(path);
    final raw = await file.readAsString();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    final metaPayload = payload['meta'] as Map<String, dynamic>? ?? const {};

    final accountItems = (payload['accounts'] as List<dynamic>? ?? const [])
        .map(
          (item) => Account(
            id: item['id'] as String,
            name: item['name'] as String,
            accountType: AccountType.values.byName(item['account_type'] as String),
            reportGroup: ReportGroup.values.byName(item['report_group'] as String),
            currency: item['currency'] as String? ?? 'MYR',
            initialBalance: (item['initial_balance'] as num?)?.toDouble() ?? 0,
            currentBalance: (item['current_balance'] as num?)?.toDouble() ?? 0,
            institution: item['institution'] as String?,
            note: item['note'] as String?,
            isActive: item['is_active'] as bool? ?? true,
          ),
        )
        .toList();
    final categoryItems = (payload['categories'] as List<dynamic>? ?? const [])
        .map(
          (item) => Category(
            id: item['id'] as String,
            name: item['name'] as String,
            type: CategoryType.values.byName(item['type'] as String),
            parentId: item['parent_id'] as String?,
          ),
        )
        .toList();
    final budgetItems = (payload['budgets'] as List<dynamic>? ?? const [])
        .map(
          (item) => Budget(
            id: item['id'] as String,
            categoryId: item['category_id'] as String,
            monthKey: item['month_key'] as String,
            amount: (item['amount'] as num).toDouble(),
            alertThreshold: (item['alert_threshold'] as num?)?.toDouble() ?? 0.8,
            rolloverEnabled: item['rollover_enabled'] as bool? ?? false,
          ),
        )
        .toList();
    final transactionItems = (payload['transactions'] as List<dynamic>? ?? const [])
        .map(
          (item) => FinanceTransaction(
            id: item['id'] as String,
            type: TransactionType.values.byName(item['type'] as String),
            accountId: item['account_id'] as String,
            toAccountId: item['to_account_id'] as String?,
            categoryId: item['category_id'] as String?,
            amount: (item['amount'] as num).toDouble(),
            currency: item['currency'] as String? ?? 'MYR',
            transactionDate: DateTime.parse(item['transaction_date'] as String),
            description: item['description'] as String?,
            merchant: item['merchant'] as String?,
          ),
        )
        .toList();
    final snapshotItems = (payload['asset_snapshots'] as List<dynamic>? ?? const [])
        .map(
          (item) => AssetSnapshot(
            id: item['id'] as String,
            accountId: item['account_id'] as String,
            snapshotDate: DateTime.parse(item['snapshot_date'] as String),
            marketValue: (item['market_value'] as num).toDouble(),
            costBasis: (item['cost_basis'] as num?)?.toDouble() ?? 0,
            cashBalance: (item['cash_balance'] as num?)?.toDouble() ?? 0,
            unrealizedPnl: (item['unrealized_pnl'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();

    final hasAnyData = accountItems.isNotEmpty ||
        categoryItems.isNotEmpty ||
        budgetItems.isNotEmpty ||
        transactionItems.isNotEmpty ||
        snapshotItems.isNotEmpty;
    if (!hasAnyData) {
      throw const FormatException('Import file does not contain any finance data.');
    }

    await database.replaceAllWithSeedData(
      accountItems: accountItems,
      categoryItems: categoryItems,
      budgetItems: budgetItems,
      transactionItems: transactionItems,
      snapshotItems: snapshotItems,
      metaValues: {
        for (final entry in metaPayload.entries) entry.key: '${entry.value}',
      },
    );
    return refresh();
  }

  Future<ImportPreview> previewImportJson(String path) async {
    final file = File(path);
    final raw = await file.readAsString();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    return ImportPreview(
      accounts: (payload['accounts'] as List<dynamic>? ?? const []).length,
      categories: (payload['categories'] as List<dynamic>? ?? const []).length,
      budgets: (payload['budgets'] as List<dynamic>? ?? const []).length,
      transactions: (payload['transactions'] as List<dynamic>? ?? const []).length,
      assetSnapshots: (payload['asset_snapshots'] as List<dynamic>? ?? const []).length,
      exportedAt: payload['exported_at'] as String?,
    );
  }

  Future<FinanceRepository> addCategory(Category category) async {
    await database.insertCategory(category);
    return refresh();
  }

  Future<FinanceRepository> updateExistingCategory(Category category) async {
    await database.updateCategory(category);
    return refresh();
  }

  Future<bool> canDeleteCategory(String categoryId) {
    return database.categoryHasLinkedData(categoryId).then((hasLinks) => !hasLinks);
  }

  Future<FinanceRepository?> deleteCategoryIfSafe(String categoryId) async {
    final deleted = await database.deleteCategoryIfSafe(categoryId);
    if (!deleted) {
      return null;
    }
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

  Future<FinanceRepository> updateExistingAssetSnapshot(AssetSnapshot snapshot) async {
    await database.updateAssetSnapshot(snapshot);
    return refresh();
  }

  Future<FinanceRepository> deleteExistingAssetSnapshot(String snapshotId) async {
    await database.deleteAssetSnapshot(snapshotId);
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

  Budget? _budgetForCategoryInMonth(String categoryId, String monthKey) {
    Budget? latest;
    for (final budget in _budgets.where((item) => item.categoryId == categoryId)) {
      if (_compareMonthKeys(budget.monthKey, monthKey) > 0) {
        continue;
      }
      if (latest == null || _compareMonthKeys(budget.monthKey, latest.monthKey) > 0) {
        latest = budget;
      }
    }
    return latest;
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

  Future<String> _defaultExportPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return p.join(directory.path, 'finance_compass_export_$timestamp.json');
  }
}

class ImportPreview {
  const ImportPreview({
    required this.accounts,
    required this.categories,
    required this.budgets,
    required this.transactions,
    required this.assetSnapshots,
    required this.exportedAt,
  });

  final int accounts;
  final int categories;
  final int budgets;
  final int transactions;
  final int assetSnapshots;
  final String? exportedAt;
}

class InvestmentFlowSummary {
  const InvestmentFlowSummary({
    required this.contribution,
    required this.withdrawal,
  });

  final double contribution;
  final double withdrawal;

  double get netContribution => contribution - withdrawal;
}
