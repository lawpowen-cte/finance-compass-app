import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart'
    hide Account, AssetSnapshot, Budget, Category;
import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/forecast_summary.dart';
import '../models/monthly_summary.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/id_generator.dart';
import '../utils/month_key.dart';
import 'sample_data.dart';

class FinanceRepository {
  static const _exchangeRatesMetaKey = 'exchange_rates_to_base_json';
  static const _currencyPriorityMetaKey = 'currency_priority_json';

  FinanceRepository._({
    required this.database,
    required List<Account> accounts,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<FinanceTransaction> transactions,
    required List<AssetSnapshot> snapshots,
    required Map<String, String> metaValues,
  })  : _accounts = accounts,
        _categories = categories,
        _budgets = budgets,
        _transactions = transactions,
        _snapshots = snapshots,
        _metaValues = metaValues;

  final AppDatabase database;

  final List<Account> _accounts;
  final List<Category> _categories;
  final List<Budget> _budgets;
  final List<FinanceTransaction> _transactions;
  final List<AssetSnapshot> _snapshots;
  final Map<String, String> _metaValues;

  static FinanceRepository preview() {
    final repository = FinanceRepository._(
      database: AppDatabase(),
      accounts: SampleData.accounts(),
      categories: SampleData.categories(),
      budgets: SampleData.budgets(),
      transactions: SampleData.transactions(),
      snapshots: SampleData.snapshots(),
      metaValues: const {},
    );
    setActiveBaseCurrency(repository.baseCurrency);
    return repository;
  }

  static Future<FinanceRepository> load(AppDatabase database) async {
    final accounts = await database.fetchAccounts();
    final categories = await database.fetchCategories();
    final budgets = await database.fetchBudgets();
    final transactions = await database.fetchTransactions();
    final snapshots = await database.fetchAssetSnapshots();
    final metaValues = await database.fetchAllMetaValues();

    final repository = FinanceRepository._(
      database: database,
      accounts: accounts,
      categories: categories,
      budgets: budgets,
      transactions: transactions,
      snapshots: snapshots,
      metaValues: metaValues,
    );
    setActiveBaseCurrency(repository.baseCurrency);
    return repository;
  }

  Future<FinanceRepository> refresh() => FinanceRepository.load(database);

  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);
  List<AssetSnapshot> get snapshots => List.unmodifiable(_snapshots);
  Map<String, String> get metaValues => Map.unmodifiable(_metaValues);

  List<String> get currencyPriority {
    final raw = _metaValues[_currencyPriorityMetaKey];
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final ordered = decoded
              .map((item) => normalizeCurrency('$item'))
              .where(supportedCurrencies.contains)
              .toSet()
              .toList();
          return [
            ...ordered,
            ...supportedCurrencies.where((item) => !ordered.contains(item)),
          ];
        }
      } catch (_) {
        // Keep the default order if metadata was edited manually.
      }
    }
    return List.unmodifiable(supportedCurrencies);
  }

  String get baseCurrency => currencyPriority.first;

  Map<String, double> get exchangeRatesToBase {
    final raw = _metaValues[_exchangeRatesMetaKey];
    if (raw == null || raw.trim().isEmpty) {
      return _defaultRatesForBase(baseCurrency);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final rates = {
          for (final entry in decoded.entries)
            normalizeCurrency(entry.key): entry.value is num
                ? (entry.value as num).toDouble()
                : double.tryParse('${entry.value}') ?? 1,
        };
        return normalizedExchangeRatesToBase(
          rates,
          baseCurrency: baseCurrency,
        );
      }
    } catch (_) {
      // Fall back to defaults if older metadata was edited manually.
    }
    return _defaultRatesForBase(baseCurrency);
  }

  String? get secondaryCurrency {
    final priority = currencyPriority;
    return priority.length < 2 ? null : priority[1];
  }

  double convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    return convertCurrencyAmount(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  double convertToBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: currency,
      toCurrency: baseCurrency,
    );
  }

  double transactionAmountInBase(FinanceTransaction transaction) {
    return convertToBase(transaction.amount, transaction.currency);
  }

  double transferIncomingAmountInBase(FinanceTransaction transaction) {
    return convertToBase(
      transaction.transferInAmount,
      transaction.transferInCurrency,
    );
  }

  double convertFromBase(double amount, String currency) {
    return convertAmount(
      amount: amount,
      fromCurrency: baseCurrency,
      toCurrency: currency,
    );
  }

  String conversionHintForAmount(double amount, String currency) {
    final normalized = normalizeCurrency(currency);
    final targetCurrency =
        normalized == baseCurrency ? secondaryCurrency : baseCurrency;
    if (targetCurrency == null || targetCurrency == normalized) {
      return '';
    }
    return formatConversionHint(
      amount: amount,
      fromCurrency: normalized,
      toCurrency: targetCurrency,
      ratesToBase: exchangeRatesToBase,
      baseCurrency: baseCurrency,
    );
  }

  Future<FinanceRepository> updateExchangeRates(
    Map<String, double> ratesToBase,
    List<String> currencyPriority,
  ) async {
    final ordered = _normalizeCurrencyPriority(currencyPriority);
    final normalized = normalizedExchangeRatesToBase(
      ratesToBase,
      baseCurrency: ordered.first,
    );
    await database.setMetaValue(_exchangeRatesMetaKey, jsonEncode(normalized));
    await database.setMetaValue(_currencyPriorityMetaKey, jsonEncode(ordered));
    return refresh();
  }

  List<TransactionTemplate> get transactionTemplates {
    final raw = _metaValues['transaction_templates_json'];
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TransactionTemplate.fromJson)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<RecurringTransactionRule> get recurringTransactionRules {
    final raw = _metaValues['recurring_transaction_rules_json'];
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RecurringTransactionRule.fromJson)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<AssetGoal> get assetGoals {
    final raw = _metaValues['asset_goals_json'];
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AssetGoal.fromJson)
            .toList()
          ..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
      }
      if (decoded is List<dynamic>) {
        return decoded
            .map((item) =>
                AssetGoal.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList()
          ..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
      }
    }

    final legacyAmountRaw = _metaValues['asset_goal_amount'];
    final legacyReachedAtRaw = _metaValues['asset_goal_reached_at'];
    final legacyAmount =
        legacyAmountRaw == null ? null : double.tryParse(legacyAmountRaw);
    if (legacyAmount == null || legacyAmount <= 0) {
      return const [];
    }
    return [
      AssetGoal(
        id: 'goal_legacy',
        name: '总资产目标',
        targetAmount: legacyAmount,
        reachedAt: legacyReachedAtRaw == null
            ? null
            : DateTime.tryParse(legacyReachedAtRaw),
      ),
    ];
  }

  double totalAssetsByGroup(ReportGroup group) {
    return displayTotalAssetsByGroup(group,
        cutoffDate: currentMonthCutoffDate());
  }

  double displayTotalAssetsByGroup(ReportGroup group, {DateTime? cutoffDate}) {
    final targetDate = cutoffDate ?? currentMonthCutoffDate();
    return _accounts.where((account) => account.reportGroup == group).fold(
          0.0,
          (sum, account) => sum + accountBalanceAtBase(account.id, targetDate),
        );
  }

  double totalAssets({bool includeCredit = true}) {
    return displayTotalAssets(
      includeCredit: includeCredit,
      cutoffDate: currentMonthCutoffDate(),
    );
  }

  double displayTotalAssets({bool includeCredit = true, DateTime? cutoffDate}) {
    final targetDate = cutoffDate ?? currentMonthCutoffDate();
    return _accounts
        .where((account) =>
            includeCredit || account.reportGroup != ReportGroup.credit)
        .fold(
            0.0,
            (sum, account) =>
                sum + accountBalanceAtBase(account.id, targetDate));
  }

  double totalTargetAssets() {
    return displayTotalAssets(
      includeCredit: false,
      cutoffDate: currentMonthCutoffDate(),
    );
  }

  List<AssetGoalHistoryPoint> totalAssetHistory({
    DateTime? cutoffDate,
  }) {
    final targetCutoff = cutoffDate ?? currentMonthCutoffDate();
    final monthKeys = <String>{
      monthKeyFromDate(targetCutoff),
      ..._transactions
          .where((item) => !item.transactionDate.isAfter(targetCutoff))
          .map((item) => monthKeyFromDate(item.transactionDate)),
      ..._snapshots
          .where((item) => !item.snapshotDate.isAfter(targetCutoff))
          .map((item) => monthKeyFromDate(item.snapshotDate)),
    }.toList()
      ..sort(_compareMonthKeys);

    if (monthKeys.isEmpty) {
      final now = DateTime.now();
      return [
        AssetGoalHistoryPoint(
          date: now,
          label: '${now.year}-${now.month.toString().padLeft(2, '0')}',
          totalAssets: totalTargetAssets(),
        ),
      ];
    }

    return monthKeys.map((monthKey) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final isCutoffMonth = monthKey == monthKeyFromDate(targetCutoff);
      final date = isCutoffMonth ? targetCutoff : DateTime(year, month + 1, 0);
      return AssetGoalHistoryPoint(
        date: date,
        label: monthKey,
        totalAssets: totalAssetsAt(date, includeCredit: false),
      );
    }).toList();
  }

  List<AssetGoalProgressSummary> assetGoalSummaries({
    DateTime? cutoffDate,
  }) {
    final targetCutoff = cutoffDate ?? currentMonthCutoffDate();
    final history = totalAssetHistory(cutoffDate: targetCutoff);
    final currentAssets = totalAssetsAt(targetCutoff, includeCredit: false);
    final summaries = assetGoals.map((goal) {
      AssetGoalHistoryPoint? reachedPoint;
      for (final point in history) {
        if (point.totalAssets >= goal.targetAmount) {
          reachedPoint = point;
          break;
        }
      }

      return AssetGoalProgressSummary(
        goal: goal,
        currentAssets: currentAssets,
        reachedAt: reachedPoint?.date ?? goal.reachedAt,
        history: history,
      );
    }).toList();

    summaries.sort((left, right) {
      if (left.isReached != right.isReached) {
        return left.isReached ? 1 : -1;
      }
      if (left.isReached && right.isReached) {
        final leftDate = left.reachedAt ?? DateTime(9999);
        final rightDate = right.reachedAt ?? DateTime(9999);
        return leftDate.compareTo(rightDate);
      }
      return left.goal.targetAmount.compareTo(right.goal.targetAmount);
    });
    return summaries;
  }

  double expenseTotalForCategory(String categoryId, String monthKey) {
    return actualExpenseTotalForCategory(categoryId, monthKey);
  }

  double actualExpenseTotalForCategory(String categoryId, String monthKey) {
    return _transactions
        .where((transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.status != TransactionStatus.planned &&
            transaction.categoryId == categoryId &&
            _monthKey(transaction.transactionDate) == monthKey)
        .fold(0,
            (sum, transaction) => sum + transactionAmountInBase(transaction));
  }

  double plannedExpenseTotalForCategory(String categoryId, String monthKey) {
    return _transactions
        .where((transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.status == TransactionStatus.planned &&
            transaction.categoryId == categoryId &&
            _monthKey(transaction.transactionDate) == monthKey)
        .fold(0,
            (sum, transaction) => sum + transactionAmountInBase(transaction));
  }

  Map<String, double> expenseBreakdownForAccount(
      String accountId, String monthKey) {
    final map = <String, double>{};

    for (final transaction in _transactions.where((item) =>
        item.accountId == accountId &&
        item.type == TransactionType.expense &&
        item.status != TransactionStatus.planned &&
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
    final items = [..._categories]..sort((a, b) {
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

  double accountBalanceAt(String accountId, DateTime date) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    return _accountBalanceAt(account, date);
  }

  double accountBalanceAtBase(String accountId, DateTime date) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    return convertToBase(_accountBalanceAt(account, date), account.currency);
  }

  double transactionDeltaForAccount(
    String accountId,
    FinanceTransaction transaction,
  ) {
    return _transactionDeltaForAccount(accountId, transaction);
  }

  String? reconciledMonthForAccount(String accountId) {
    final monthKey = _metaValues[_accountReconciliationKey(accountId)];
    if (monthKey == null || monthKey.trim().isEmpty) {
      return null;
    }
    return monthKey;
  }

  bool isAccountReconciledForMonth(String accountId, String monthKey) {
    final reconciledMonth = reconciledMonthForAccount(accountId);
    if (reconciledMonth == null) {
      return false;
    }
    return _compareMonthKeys(reconciledMonth, monthKey) >= 0;
  }

  Future<FinanceRepository> setAccountReconciledMonth(
    String accountId,
    String monthKey,
  ) async {
    await database.setMetaValue(
      _accountReconciliationKey(accountId),
      monthKey,
    );
    return refresh();
  }

  Future<FinanceRepository> clearAccountReconciledMonth(
      String accountId) async {
    await database.deleteMetaValue(_accountReconciliationKey(accountId));
    return refresh();
  }

  AccountBalanceTrace accountBalanceTrace(
    String accountId,
    DateTime cutoffDate,
  ) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    final accountSnapshots = snapshotsForAccount(account.id);
    AssetSnapshot? latestSnapshotBeforeDate;
    for (final snapshot in accountSnapshots) {
      if (!snapshot.snapshotDate.isAfter(cutoffDate)) {
        latestSnapshotBeforeDate = snapshot;
      }
    }

    final sourceDate = latestSnapshotBeforeDate?.snapshotDate;
    var runningBalance =
        latestSnapshotBeforeDate?.marketValue ?? account.currentBalance;
    final traceEntries = <AccountBalanceTraceEntry>[];
    final reversingTransactions = _transactions.where((transaction) {
      if (!transaction.transactionDate.isAfter(cutoffDate)) {
        return false;
      }
      if (sourceDate != null &&
          !transaction.transactionDate.isAfter(sourceDate)) {
        return false;
      }
      return _transactionDeltaForAccount(account.id, transaction) != 0;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    for (final transaction in reversingTransactions) {
      final appliedDelta =
          -_transactionDeltaForAccount(account.id, transaction);
      runningBalance += appliedDelta;
      traceEntries.add(
        AccountBalanceTraceEntry(
          transactionId: transaction.id,
          date: transaction.transactionDate,
          title: _traceTitleForTransaction(transaction),
          subtitle: _traceSubtitleForTransaction(account.id, transaction),
          delta: appliedDelta,
          runningBalance: runningBalance,
        ),
      );
    }

    final sourceLabel = latestSnapshotBeforeDate == null
        ? '当前账户余额'
        : '资产快照 ${_dateLabel(latestSnapshotBeforeDate.snapshotDate)}';
    return AccountBalanceTrace(
      account: account,
      cutoffDate: cutoffDate,
      sourceLabel: sourceLabel,
      sourceAmount:
          latestSnapshotBeforeDate?.marketValue ?? account.currentBalance,
      entries: traceEntries,
      endingBalance: runningBalance,
    );
  }

  List<Account> investmentAccounts() {
    return _accounts
        .where(
          (item) =>
              item.reportGroup == ReportGroup.investment ||
              item.reportGroup == ReportGroup.retirement,
        )
        .toList();
  }

  AssetSnapshot? latestSnapshotForAccount(String accountId) {
    final items = _snapshots
        .where((item) => item.accountId == accountId)
        .toList()
      ..sort((a, b) => b.snapshotDate.compareTo(a.snapshotDate));
    return items.isEmpty ? null : items.first;
  }

  AssetSnapshot? latestSnapshotForAccountUpTo(String accountId, DateTime date) {
    final items = _snapshots
        .where((item) =>
            item.accountId == accountId && !item.snapshotDate.isAfter(date))
        .toList()
      ..sort((a, b) => b.snapshotDate.compareTo(a.snapshotDate));
    return items.isEmpty ? null : items.first;
  }

  List<AssetSnapshot> snapshotsForAccount(String accountId) {
    final items = _snapshots
        .where((item) => item.accountId == accountId)
        .toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    return items;
  }

  List<AssetSnapshot> snapshotsForAccountUpTo(String accountId, DateTime date) {
    final items = _snapshots
        .where((item) =>
            item.accountId == accountId && !item.snapshotDate.isAfter(date))
        .toList()
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
    final targetDate = upToDate ?? currentMonthCutoffDate();
    final firstSnapshot = firstSnapshotForAccount(accountId);
    if (firstSnapshot == null) {
      return investmentFlowSummaryForAccount(
        accountId,
        upToDate: targetDate,
      ).contribution;
    }

    if (targetDate.isBefore(firstSnapshot.snapshotDate)) {
      return firstSnapshot.costBasis;
    }

    final deltaFlow = investmentFlowSummaryForAccount(
      accountId,
      fromDateExclusive: firstSnapshot.snapshotDate,
      upToDate: targetDate,
    );
    return (firstSnapshot.costBasis + deltaFlow.contribution)
        .clamp(0, double.infinity)
        .toDouble();
  }

  double snapshotCostBasis(AssetSnapshot snapshot) {
    return costBasisForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
  }

  double cashBalanceForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final targetDate = upToDate ?? currentMonthCutoffDate();
    final account = _accounts.firstWhere((item) => item.id == accountId);
    final latestSnapshot = latestSnapshotForAccountUpTo(accountId, targetDate);
    if (latestSnapshot == null) {
      return _accountBalanceAt(account, targetDate)
          .clamp(0, double.infinity)
          .toDouble();
    }

    var cashBalance = latestSnapshot.cashBalance;
    for (final transaction in _transactions) {
      if (!transaction.transactionDate.isAfter(targetDate) ||
          !transaction.transactionDate.isAfter(latestSnapshot.snapshotDate)) {
        continue;
      }
      cashBalance -= _cashDeltaForAccount(accountId, transaction);
    }
    return cashBalance.clamp(0, double.infinity).toDouble();
  }

  double remainingCostBasisForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final targetDate = upToDate ?? currentMonthCutoffDate();
    final cumulativeCost = costBasisForAccount(
      accountId,
      upToDate: targetDate,
    );
    final flow = investmentFlowSummaryForAccount(
      accountId,
      upToDate: targetDate,
    );
    return (cumulativeCost - flow.withdrawal)
        .clamp(0, double.infinity)
        .toDouble();
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

  double totalAssetsAt(DateTime date, {bool includeCredit = true}) {
    return _accounts
        .where((account) =>
            includeCredit || account.reportGroup != ReportGroup.credit)
        .fold(
          0.0,
          (sum, account) =>
              sum +
              convertToBase(_accountBalanceAt(account, date), account.currency),
        );
  }

  InvestmentFlowSummary investmentFlowSummaryForAccount(
    String accountId, {
    DateTime? fromDateExclusive,
    DateTime? upToDate,
  }) {
    double contribution = 0;
    double withdrawal = 0;

    for (final transaction in _transactions) {
      if (!transaction.affectsBalance) {
        continue;
      }
      if (fromDateExclusive != null &&
          !transaction.transactionDate.isAfter(fromDateExclusive)) {
        continue;
      }
      if (upToDate != null && transaction.transactionDate.isAfter(upToDate)) {
        continue;
      }

      if (transaction.type == TransactionType.transfer) {
        if (transaction.toAccountId == accountId) {
          contribution += transaction.transferInAmount;
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
              item.transactionDate
                  .isAfter(DateTime(now.year, now.month, now.day)),
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
              item.transactionDate
                  .isAfter(DateTime(now.year, now.month, now.day - 1)) &&
              item.transactionDate.isBefore(lastDate),
        )
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  List<MonthlySummary> futureExpenseSummaries({int months = 3}) {
    final now = DateTime.now();
    return List.generate(months, (index) {
      final date = DateTime(now.year, now.month + index + 1);
      final monthKey = _monthKey(date);
      return MonthlySummary(
        monthKey: monthKey,
        income: totalIncomeForMonth(monthKey) + plannedIncomeForMonth(monthKey),
        expense:
            totalExpenseForMonth(monthKey) + plannedExpenseForMonth(monthKey),
      );
    });
  }

  List<CashFlowProjectionPoint> futureCashFlowProjection({int months = 6}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startMonth = DateTime(now.year, now.month);
    var runningCash = displayTotalAssetsByGroup(
          ReportGroup.cash,
          cutoffDate: currentMonthCutoffDate(),
        ) +
        displayTotalAssetsByGroup(
          ReportGroup.credit,
          cutoffDate: currentMonthCutoffDate(),
        );

    return List.generate(months, (index) {
      final monthDate = DateTime(startMonth.year, startMonth.month + index);
      final monthKey = _monthKey(monthDate);
      var income = 0.0;
      var expense = 0.0;
      var transfers = 0.0;

      for (final transaction in _transactions.where(
        (item) => _monthKey(item.transactionDate) == monthKey,
      )) {
        if (transaction.transactionDate.isBefore(today) &&
            transaction.status != TransactionStatus.planned) {
          continue;
        }
        final delta = _cashFlowDelta(transaction);
        if (delta == 0) {
          continue;
        }
        switch (transaction.type) {
          case TransactionType.income:
            income += delta;
            break;
          case TransactionType.expense:
            expense += delta.abs();
            break;
          case TransactionType.transfer:
          case TransactionType.adjustment:
            transfers += delta;
            break;
        }
      }

      final net = income - expense + transfers;
      runningCash += net;
      return CashFlowProjectionPoint(
        monthKey: monthKey,
        income: income,
        expense: expense,
        transfers: transfers,
        net: net,
        endingCash: runningCash,
      );
    });
  }

  List<CreditCardPaymentReminder> creditCardPaymentReminders({
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final dueDate = DateTime(now.year, now.month + 1, 25);
    return _accounts
        .where((account) => account.reportGroup == ReportGroup.credit)
        .map((account) {
          final balance =
              accountBalanceAt(account.id, currentMonthCutoffDate());
          return CreditCardPaymentReminder(
            account: account,
            amountDue: balance < 0 ? balance.abs() : 0,
            dueDate: dueDate,
          );
        })
        .where((item) => item.amountDue > 0)
        .toList()
      ..sort((a, b) => b.amountDue.compareTo(a.amountDue));
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
    final items = [..._budgets]..sort((a, b) {
        final categoryCompare =
            categoryName(a.categoryId).compareTo(categoryName(b.categoryId));
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
      if (existing == null ||
          _compareMonthKeys(budget.monthKey, existing.monthKey) > 0) {
        latestByCategory[budget.categoryId] = budget;
      }
    }
    final items = latestByCategory.values.toList()
      ..sort((a, b) =>
          categoryName(a.categoryId).compareTo(categoryName(b.categoryId)));
    return items;
  }

  List<String> budgetMonthKeys({int futureMonths = 6}) {
    final now = DateTime.now();
    final monthKeys = <String>{
      monthKeyFromDate(now),
      ..._transactions.map((item) => monthKeyFromDate(item.transactionDate)),
      ..._budgets.map((item) => item.monthKey),
      ...List.generate(
          futureMonths,
          (index) =>
              monthKeyFromDate(DateTime(now.year, now.month + index + 1))),
    }.toList()
      ..sort((a, b) => _compareMonthKeys(b, a));
    return monthKeys;
  }

  double totalBudgetAmount({String? monthKey}) {
    final items = monthKey == null ? _budgets : activeBudgetsForMonth(monthKey);
    return items.fold(0, (sum, item) => sum + budgetAmountInBase(item));
  }

  double budgetAmountInBase(Budget budget) {
    return convertToBase(budget.amount, budget.currency);
  }

  double totalBudgetExpenseForMonth(String monthKey) {
    final budgetCategoryIds =
        activeBudgetsForMonth(monthKey).map((item) => item.categoryId).toSet();
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.status != TransactionStatus.planned &&
              item.categoryId != null &&
              budgetCategoryIds.contains(item.categoryId) &&
              _monthKey(item.transactionDate) == monthKey,
        )
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  double totalPlannedBudgetExpenseForMonth(String monthKey) {
    final budgetCategoryIds =
        activeBudgetsForMonth(monthKey).map((item) => item.categoryId).toSet();
    return _transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.status == TransactionStatus.planned &&
              item.categoryId != null &&
              budgetCategoryIds.contains(item.categoryId) &&
              _monthKey(item.transactionDate) == monthKey,
        )
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
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
    for (final currentMonthKey
        in _monthKeyRange(firstBudget.monthKey, monthKey)) {
      final activeBudget =
          _budgetForCategoryInMonth(budget.categoryId, currentMonthKey);
      if (activeBudget == null) {
        carry = 0.0;
        continue;
      }
      final effective = budgetAmountInBase(activeBudget) + carry;
      if (currentMonthKey == monthKey) {
        return effective;
      }
      final spent =
          expenseTotalForCategory(activeBudget.categoryId, currentMonthKey);
      carry = activeBudget.rolloverEnabled ? (effective - spent) : 0.0;
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
      if (transaction.status == TransactionStatus.planned) {
        continue;
      }
      if (type == CategoryType.expense &&
          transaction.type != TransactionType.expense) {
        continue;
      }
      if (type == CategoryType.income &&
          transaction.type != TransactionType.income) {
        continue;
      }
      totals[categoryId] =
          (totals[categoryId] ?? 0) + transactionAmountInBase(transaction);
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
        summaries.fold<double>(0, (sum, item) => sum + item.income) /
            summaries.length;
    final averageExpense =
        summaries.fold<double>(0, (sum, item) => sum + item.expense) /
            summaries.length;
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
        .where((item) =>
            item.type == TransactionType.income &&
            item.status != TransactionStatus.planned &&
            _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  double totalExpenseForMonth(String monthKey) {
    return _transactions
        .where((item) =>
            item.type == TransactionType.expense &&
            item.status != TransactionStatus.planned &&
            _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  double plannedIncomeForMonth(String monthKey) {
    return _transactions
        .where((item) =>
            item.type == TransactionType.income &&
            item.status == TransactionStatus.planned &&
            _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  double plannedExpenseForMonth(String monthKey) {
    return _transactions
        .where((item) =>
            item.type == TransactionType.expense &&
            item.status == TransactionStatus.planned &&
            _monthKey(item.transactionDate) == monthKey)
        .fold(0, (sum, item) => sum + transactionAmountInBase(item));
  }

  Future<FinanceRepository> addAccount(Account account) async {
    await database.insertAccount(account);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> updateExistingAccount(Account account) async {
    await database.updateAccount(account);
    return _refreshWithGoalSync();
  }

  Future<bool> canDeleteAccount(String accountId) {
    return database
        .accountHasLinkedData(accountId)
        .then((hasLinks) => !hasLinks);
  }

  Future<FinanceRepository?> deleteAccountIfSafe(String accountId) async {
    final deleted = await database.deleteAccountIfSafe(accountId);
    if (!deleted) {
      return null;
    }
    await database.deleteMetaValue(_accountReconciliationKey(accountId));
    return refresh();
  }

  Future<FinanceRepository> clearAllData() async {
    await database.clearAllUserData();
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> loadExampleData() async {
    await database.replaceAllWithSeedData(
      accountItems: SampleData.accounts(),
      categoryItems: SampleData.categories(),
      budgetItems: SampleData.budgets(),
      transactionItems: SampleData.transactions(),
      snapshotItems: SampleData.snapshots(),
    );
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> addAssetGoal({
    required String name,
    required double amount,
  }) async {
    final nextGoals = [
      ...assetGoals,
      AssetGoal(
        id: buildId('goal'),
        name: name,
        targetAmount: amount,
      ),
    ];
    await _saveAssetGoals(nextGoals);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> updateAssetGoal(AssetGoal goal) async {
    final nextGoals =
        assetGoals.map((item) => item.id == goal.id ? goal : item).toList();
    await _saveAssetGoals(nextGoals);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> deleteAssetGoal(String goalId) async {
    final nextGoals = assetGoals.where((item) => item.id != goalId).toList();
    await _saveAssetGoals(nextGoals);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> addTransactionTemplate({
    required String name,
    required FinanceTransaction transaction,
  }) async {
    final template = TransactionTemplate.fromTransaction(
      id: buildId('tpl'),
      name: name,
      transaction: transaction,
    );
    await _saveTransactionTemplates([
      ...transactionTemplates.where((item) => item.name != name),
      template,
    ]);
    return refresh();
  }

  Future<FinanceRepository> deleteTransactionTemplate(String templateId) async {
    await _saveTransactionTemplates(
      transactionTemplates.where((item) => item.id != templateId).toList(),
    );
    return refresh();
  }

  Future<FinanceRepository> addRecurringTransactionRule({
    required String name,
    required FinanceTransaction transaction,
    int intervalMonths = 1,
  }) async {
    final rule = RecurringTransactionRule.fromTransaction(
      id: buildId('rule'),
      name: name,
      transaction: transaction,
      intervalMonths: intervalMonths,
    );
    await _saveRecurringTransactionRules([
      ...recurringTransactionRules.where((item) => item.name != name),
      rule,
    ]);
    return refresh();
  }

  Future<FinanceRepository> deleteRecurringTransactionRule(
      String ruleId) async {
    await _saveRecurringTransactionRules(
      recurringTransactionRules.where((item) => item.id != ruleId).toList(),
    );
    return refresh();
  }

  Future<FinanceRepository> generateRecurringTransactions(
    String ruleId, {
    int monthsAhead = 6,
  }) async {
    final rules = recurringTransactionRules;
    RecurringTransactionRule? rule;
    for (final item in rules) {
      if (item.id == ruleId) {
        rule = item;
        break;
      }
    }
    final activeRule = rule;
    if (activeRule == null || !activeRule.isActive) {
      return refresh();
    }

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + monthsAhead, now.day);
    final generatedKeys = {...activeRule.generatedMonthKeys};
    final transactions = <FinanceTransaction>[];
    var generatedCount = 0;
    var cursor = DateTime(
      activeRule.startDate.year,
      activeRule.startDate.month,
      activeRule.startDate.day,
    );

    while (!cursor.isAfter(endDate)) {
      final currentMonthKey = _monthKey(cursor);
      if (!generatedKeys.contains(currentMonthKey) &&
          (activeRule.endDate == null ||
              !cursor.isAfter(activeRule.endDate!))) {
        final isFuture = cursor.isAfter(DateTime(now.year, now.month, now.day));
        transactions.add(
          activeRule.toTransaction(
            id: '${buildId('txn')}_${generatedCount++}',
            date: cursor,
            status: isFuture ? TransactionStatus.planned : activeRule.status,
          ),
        );
        generatedKeys.add(currentMonthKey);
      }
      cursor = DateTime(
        cursor.year,
        cursor.month + activeRule.intervalMonths,
        cursor.day,
      );
    }

    if (transactions.isNotEmpty) {
      await database.insertTransactions(transactions);
    }
    final nextRules = rules
        .map(
          (item) => item.id == activeRule.id
              ? item.copyWith(generatedMonthKeys: generatedKeys.toList())
              : item,
        )
        .toList();
    await _saveRecurringTransactionRules(nextRules);
    return _refreshWithGoalSync();
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
              'currency': item.currency,
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
              'to_amount': item.toAmount,
              'to_currency': item.toCurrency,
              'record_date': item.recordDate.toIso8601String(),
              'transaction_date': item.transactionDate.toIso8601String(),
              'status': item.status.name,
              'recurring_rule_id': item.recurringRuleId,
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
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Map<String, dynamic> buildAiSummaryPayload(
      {required List<String> monthKeys}) {
    final includedMonths = monthKeys.where((monthKey) {
      return totalIncomeForMonth(monthKey) != 0 ||
          totalExpenseForMonth(monthKey) != 0 ||
          plannedIncomeForMonth(monthKey) != 0 ||
          plannedExpenseForMonth(monthKey) != 0;
    }).toList();
    final currentMonth = monthKeyFromDate(DateTime.now());
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'base_currency': baseCurrency,
      'currency_priority': currencyPriority,
      'exchange_rates_to_base': exchangeRatesToBase,
      'months': includedMonths,
      'income_by_month': {
        for (final monthKey in includedMonths)
          monthKey: totalIncomeForMonth(monthKey),
      },
      'expense_by_month': {
        for (final monthKey in includedMonths)
          monthKey: totalExpenseForMonth(monthKey),
      },
      'planned_income_by_month': {
        for (final monthKey in includedMonths)
          monthKey: plannedIncomeForMonth(monthKey),
      },
      'planned_expense_by_month': {
        for (final monthKey in includedMonths)
          monthKey: plannedExpenseForMonth(monthKey),
      },
      'net_by_month': {
        for (final monthKey in includedMonths)
          monthKey:
              totalIncomeForMonth(monthKey) - totalExpenseForMonth(monthKey),
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

  Uint8List exportFuturePlanningCsvBytes({int months = 24}) {
    final now = DateTime.now();
    final monthKeys = List.generate(
      months,
      (index) => monthKeyFromDate(DateTime(now.year, now.month + index + 1)),
    );

    final categoryIds = <String>{
      ...categoriesByType(CategoryType.expense).map((item) => item.id),
    }.where((categoryId) {
      final hasBudget = _budgets.any((item) => item.categoryId == categoryId);
      final hasFutureExpense = monthKeys.any(
        (monthKey) =>
            expenseTotalForCategory(categoryId, monthKey) != 0 ||
            plannedExpenseTotalForCategory(categoryId, monthKey) != 0,
      );
      return hasBudget || hasFutureExpense;
    }).toList()
      ..sort((a, b) => categoryName(a).compareTo(categoryName(b)));

    final lines = <List<String>>[];
    lines.add([
      'Category',
      'Base Budget',
      ...monthKeys,
      'Planned Total',
    ]);

    for (final categoryId in categoryIds) {
      final budget = _budgets
          .where((item) => item.categoryId == categoryId)
          .toList()
        ..sort((a, b) => _compareMonthKeys(b.monthKey, a.monthKey));
      final baseBudget =
          budget.isEmpty ? 0.0 : budgetAmountInBase(budget.first);
      final monthValues = monthKeys
          .map((monthKey) =>
              expenseTotalForCategory(categoryId, monthKey) +
              plannedExpenseTotalForCategory(categoryId, monthKey))
          .toList();
      final plannedTotal =
          monthValues.fold<double>(0, (sum, item) => sum + item);
      lines.add([
        categoryName(categoryId),
        _csvMoney(baseBudget),
        ...monthValues.map(_csvMoney),
        _csvMoney(plannedTotal),
      ]);
    }

    final monthlyTotals = monthKeys
        .map(
          (monthKey) => categoryIds.fold<double>(
            0,
            (sum, categoryId) =>
                sum +
                expenseTotalForCategory(categoryId, monthKey) +
                plannedExpenseTotalForCategory(categoryId, monthKey),
          ),
        )
        .toList();
    final monthlyBudgets = monthKeys
        .map(
          (monthKey) => activeBudgetsForMonth(monthKey).fold<double>(
            0,
            (sum, budget) => sum + effectiveBudgetForMonth(budget, monthKey),
          ),
        )
        .toList();

    lines.add([
      'Total Planned',
      '',
      ...monthlyTotals.map(_csvMoney),
      _csvMoney(monthlyTotals.fold<double>(0, (sum, item) => sum + item)),
    ]);
    lines.add([
      'Total Budget',
      '',
      ...monthlyBudgets.map(_csvMoney),
      _csvMoney(monthlyBudgets.fold<double>(0, (sum, item) => sum + item)),
    ]);

    final csv = lines.map((row) => row.map(_csvEscape).join(',')).join('\n');
    return Uint8List.fromList(utf8.encode(csv));
  }

  Future<String> exportAiSummaryJson(String targetPath,
      {required List<String> monthKeys}) async {
    final payload = buildAiSummaryPayload(monthKeys: monthKeys);
    final file = File(targetPath);
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
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
            accountType:
                AccountType.values.byName(item['account_type'] as String),
            reportGroup:
                ReportGroup.values.byName(item['report_group'] as String),
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
            currency: item['currency'] as String? ?? 'MYR',
            alertThreshold:
                (item['alert_threshold'] as num?)?.toDouble() ?? 0.8,
            rolloverEnabled: item['rollover_enabled'] as bool? ?? false,
          ),
        )
        .toList();
    final transactionItems =
        (payload['transactions'] as List<dynamic>? ?? const [])
            .map(
              (item) => FinanceTransaction(
                id: item['id'] as String,
                type: TransactionType.values.byName(item['type'] as String),
                accountId: item['account_id'] as String,
                toAccountId: item['to_account_id'] as String?,
                categoryId: item['category_id'] as String?,
                amount: (item['amount'] as num).toDouble(),
                currency: item['currency'] as String? ?? 'MYR',
                toAmount: (item['to_amount'] as num?)?.toDouble(),
                toCurrency: item['to_currency'] as String?,
                recordDate: DateTime.parse(
                  (item['record_date'] as String?) ??
                      item['transaction_date'] as String,
                ),
                transactionDate:
                    DateTime.parse(item['transaction_date'] as String),
                status: item['status'] == null
                    ? TransactionStatus.actual
                    : TransactionStatus.values.byName(item['status'] as String),
                recurringRuleId: item['recurring_rule_id'] as String?,
                description: item['description'] as String?,
                merchant: item['merchant'] as String?,
              ),
            )
            .toList();
    final snapshotItems =
        (payload['asset_snapshots'] as List<dynamic>? ?? const [])
            .map(
              (item) => AssetSnapshot(
                id: item['id'] as String,
                accountId: item['account_id'] as String,
                snapshotDate: DateTime.parse(item['snapshot_date'] as String),
                marketValue: (item['market_value'] as num).toDouble(),
                costBasis: (item['cost_basis'] as num?)?.toDouble() ?? 0,
                cashBalance: (item['cash_balance'] as num?)?.toDouble() ?? 0,
                unrealizedPnl:
                    (item['unrealized_pnl'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList();

    final hasAnyData = accountItems.isNotEmpty ||
        categoryItems.isNotEmpty ||
        budgetItems.isNotEmpty ||
        transactionItems.isNotEmpty ||
        snapshotItems.isNotEmpty;
    if (!hasAnyData) {
      throw const FormatException(
          'Import file does not contain any finance data.');
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
      transactions:
          (payload['transactions'] as List<dynamic>? ?? const []).length,
      assetSnapshots:
          (payload['asset_snapshots'] as List<dynamic>? ?? const []).length,
      exportedAt: payload['exported_at'] as String?,
    );
  }

  Future<FinanceRepository> addCategory(Category category) async {
    await database.insertCategory(category);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> updateExistingCategory(Category category) async {
    await database.updateCategory(category);
    return _refreshWithGoalSync();
  }

  Future<bool> canDeleteCategory(String categoryId) {
    return database
        .categoryHasLinkedData(categoryId)
        .then((hasLinks) => !hasLinks);
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
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> deleteExistingBudget(String budgetId) async {
    await database.deleteBudget(budgetId);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> addTransaction(
      FinanceTransaction transaction) async {
    await database.insertTransaction(transaction);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> addTransactions(
      List<FinanceTransaction> transactions) async {
    if (transactions.isEmpty) {
      return refresh();
    }
    await database.insertTransactions(transactions);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> updateExistingTransaction(
      FinanceTransaction transaction) async {
    await database.updateTransaction(transaction);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> deleteExistingTransaction(
      String transactionId) async {
    await database.deleteTransaction(transactionId);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> addAssetSnapshot(AssetSnapshot snapshot) async {
    await database.insertAssetSnapshot(snapshot);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> updateExistingAssetSnapshot(
      AssetSnapshot snapshot) async {
    await database.updateAssetSnapshot(snapshot);
    return _refreshWithGoalSync();
  }

  Future<FinanceRepository> deleteExistingAssetSnapshot(
      String snapshotId) async {
    await database.deleteAssetSnapshot(snapshotId);
    return _refreshWithGoalSync();
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
    return DateTime(leftYear, leftMonth)
        .compareTo(DateTime(rightYear, rightMonth));
  }

  Budget? _budgetForCategoryInMonth(String categoryId, String monthKey) {
    Budget? latest;
    for (final budget
        in _budgets.where((item) => item.categoryId == categoryId)) {
      if (_compareMonthKeys(budget.monthKey, monthKey) > 0) {
        continue;
      }
      if (latest == null ||
          _compareMonthKeys(budget.monthKey, latest.monthKey) > 0) {
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

  Future<FinanceRepository> _refreshWithGoalSync() async {
    final refreshed = await refresh();
    await refreshed._syncAssetGoalReachedAt();
    return FinanceRepository.load(database);
  }

  Future<void> _syncAssetGoalReachedAt() async {
    if (assetGoals.isEmpty) {
      await database.deleteMetaValue('asset_goals_json');
      await database.deleteMetaValue('asset_goal_amount');
      await database.deleteMetaValue('asset_goal_reached_at');
      return;
    }
    final syncedGoals = assetGoalSummaries(cutoffDate: currentMonthCutoffDate())
        .map(
          (summary) => summary.goal.copyWith(
            reachedAt: summary.reachedAt == null
                ? null
                : DateTime(
                    summary.reachedAt!.year,
                    summary.reachedAt!.month,
                    summary.reachedAt!.day,
                  ),
          ),
        )
        .toList();
    await _saveAssetGoals(syncedGoals);
    await database.deleteMetaValue('asset_goal_amount');
    await database.deleteMetaValue('asset_goal_reached_at');
  }

  Future<void> _saveAssetGoals(List<AssetGoal> goals) async {
    if (goals.isEmpty) {
      await database.deleteMetaValue('asset_goals_json');
      return;
    }
    await database.setMetaValue(
      'asset_goals_json',
      jsonEncode(goals.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveTransactionTemplates(
    List<TransactionTemplate> templates,
  ) async {
    if (templates.isEmpty) {
      await database.deleteMetaValue('transaction_templates_json');
      return;
    }
    await database.setMetaValue(
      'transaction_templates_json',
      jsonEncode(templates.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveRecurringTransactionRules(
    List<RecurringTransactionRule> rules,
  ) async {
    if (rules.isEmpty) {
      await database.deleteMetaValue('recurring_transaction_rules_json');
      return;
    }
    await database.setMetaValue(
      'recurring_transaction_rules_json',
      jsonEncode(rules.map((item) => item.toJson()).toList()),
    );
  }

  List<String> _normalizeCurrencyPriority(List<String> currencies) {
    final ordered = currencies
        .map(normalizeCurrency)
        .where(supportedCurrencies.contains)
        .toSet()
        .toList();
    return [
      ...ordered,
      ...supportedCurrencies.where((item) => !ordered.contains(item)),
    ];
  }

  Map<String, double> _defaultRatesForBase(String baseCurrency) {
    final base = normalizeCurrency(baseCurrency);
    final converted = <String, double>{};
    for (final currency in supportedCurrencies) {
      converted[currency] = convertCurrencyAmount(
        amount: 1,
        fromCurrency: currency,
        toCurrency: base,
        ratesToBase: defaultExchangeRatesToBase,
        baseCurrency: baseCurrencyCode,
      );
    }
    converted[base] = 1;
    return normalizedExchangeRatesToBase(converted, baseCurrency: base);
  }

  double _accountBalanceAt(Account account, DateTime date) {
    final accountSnapshots = snapshotsForAccount(account.id);
    AssetSnapshot? latestSnapshotBeforeDate;
    for (final snapshot in accountSnapshots) {
      if (!snapshot.snapshotDate.isAfter(date)) {
        latestSnapshotBeforeDate = snapshot;
      }
    }

    if (latestSnapshotBeforeDate != null) {
      var balance = latestSnapshotBeforeDate.marketValue;
      for (final transaction in _transactions) {
        if (!transaction.transactionDate.isAfter(date) ||
            !transaction.transactionDate
                .isAfter(latestSnapshotBeforeDate.snapshotDate)) {
          continue;
        }
        balance -= _transactionDeltaForAccount(account.id, transaction);
      }
      return balance;
    }

    var balance = account.currentBalance;
    for (final transaction in _transactions) {
      if (transaction.transactionDate.isAfter(date)) {
        balance -= _transactionDeltaForAccount(account.id, transaction);
      }
    }
    return balance;
  }

  double _transactionDeltaForAccount(
      String accountId, FinanceTransaction transaction) {
    if (!transaction.affectsBalance) {
      return 0;
    }
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.accountId == accountId ? transaction.amount : 0;
      case TransactionType.expense:
        return transaction.accountId == accountId ? -transaction.amount : 0;
      case TransactionType.adjustment:
        return transaction.accountId == accountId ? transaction.amount : 0;
      case TransactionType.transfer:
        if (transaction.accountId == accountId) {
          return -transaction.amount;
        }
        if (transaction.toAccountId == accountId) {
          return transaction.transferInAmount;
        }
        return 0;
    }
  }

  double _cashDeltaForAccount(
      String accountId, FinanceTransaction transaction) {
    if (!transaction.affectsBalance) {
      return 0;
    }
    switch (transaction.type) {
      case TransactionType.adjustment:
        return transaction.accountId == accountId ? transaction.amount : 0;
      case TransactionType.transfer:
        if (transaction.accountId == accountId) {
          return -transaction.amount;
        }
        if (transaction.toAccountId == accountId) {
          return transaction.transferInAmount;
        }
        return 0;
      case TransactionType.income:
      case TransactionType.expense:
        return 0;
    }
  }

  double _cashFlowDelta(FinanceTransaction transaction) {
    double deltaFor(String accountId, double amount, String currency) {
      final account = _accounts.firstWhere(
        (item) => item.id == accountId,
        orElse: () => Account(
          id: accountId,
          name: accountId,
          accountType: AccountType.other,
          reportGroup: ReportGroup.investment,
          currency: transaction.currency,
          currentBalance: 0,
        ),
      );
      if (account.reportGroup != ReportGroup.cash &&
          account.reportGroup != ReportGroup.credit) {
        return 0;
      }
      return convertToBase(amount, currency);
    }

    switch (transaction.type) {
      case TransactionType.income:
        return deltaFor(
            transaction.accountId, transaction.amount, transaction.currency);
      case TransactionType.expense:
        return deltaFor(
            transaction.accountId, -transaction.amount, transaction.currency);
      case TransactionType.adjustment:
        return deltaFor(
            transaction.accountId, transaction.amount, transaction.currency);
      case TransactionType.transfer:
        var delta = deltaFor(
            transaction.accountId, -transaction.amount, transaction.currency);
        final toAccountId = transaction.toAccountId;
        if (toAccountId != null) {
          delta += deltaFor(
            toAccountId,
            transaction.transferInAmount,
            transaction.transferInCurrency,
          );
        }
        return delta;
    }
  }

  String _accountReconciliationKey(String accountId) {
    return 'account_reconciled_month_$accountId';
  }

  String _traceTitleForTransaction(FinanceTransaction transaction) {
    final description = transaction.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }
    final merchant = transaction.merchant?.trim();
    if (merchant != null && merchant.isNotEmpty) {
      return merchant;
    }
    final categoryId = transaction.categoryId;
    if (categoryId != null) {
      return _categoryNameOrFallback(categoryId);
    }
    return _transactionTypeLabel(transaction.type);
  }

  String _traceSubtitleForTransaction(
    String accountId,
    FinanceTransaction transaction,
  ) {
    final parts = <String>[_transactionTypeLabel(transaction.type)];
    final categoryId = transaction.categoryId;
    if (categoryId != null) {
      parts.add(_categoryNameOrFallback(categoryId));
    }
    if (transaction.type == TransactionType.transfer &&
        transaction.toAccountId != null) {
      parts.add(
        '${_accountNameOrFallback(transaction.accountId)} -> '
        '${_accountNameOrFallback(transaction.toAccountId!)}',
      );
    } else {
      parts.add(_accountNameOrFallback(transaction.accountId));
    }
    parts.add(transaction.toAccountId == accountId ? '流入账户' : '影响账户');
    return parts.join(' · ');
  }

  String _transactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
      case TransactionType.transfer:
        return '转账';
      case TransactionType.adjustment:
        return '调整';
    }
  }

  String _categoryNameOrFallback(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return '未命名类别';
  }

  String _accountNameOrFallback(String accountId) {
    for (final account in _accounts) {
      if (account.id == accountId) {
        return account.name;
      }
    }
    return '未知账户';
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _csvMoney(double value) => value == 0 ? '' : value.toStringAsFixed(2);

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  DateTime currentMonthCutoffDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
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

class AccountBalanceTrace {
  const AccountBalanceTrace({
    required this.account,
    required this.cutoffDate,
    required this.sourceLabel,
    required this.sourceAmount,
    required this.entries,
    required this.endingBalance,
  });

  final Account account;
  final DateTime cutoffDate;
  final String sourceLabel;
  final double sourceAmount;
  final List<AccountBalanceTraceEntry> entries;
  final double endingBalance;
}

class AccountBalanceTraceEntry {
  const AccountBalanceTraceEntry({
    required this.transactionId,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.delta,
    required this.runningBalance,
  });

  final String transactionId;
  final DateTime date;
  final String title;
  final String subtitle;
  final double delta;
  final double runningBalance;
}

class TransactionTemplate {
  const TransactionTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.accountId,
    required this.amount,
    required this.currency,
    this.status = TransactionStatus.actual,
    this.toAccountId,
    this.toAmount,
    this.toCurrency,
    this.categoryId,
    this.description,
    this.merchant,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final double? toAmount;
  final String? toCurrency;
  final TransactionStatus status;
  final String? description;
  final String? merchant;

  factory TransactionTemplate.fromTransaction({
    required String id,
    required String name,
    required FinanceTransaction transaction,
  }) {
    return TransactionTemplate(
      id: id,
      name: name,
      type: transaction.type,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      currency: transaction.currency,
      toAmount: transaction.toAmount,
      toCurrency: transaction.toCurrency,
      status: transaction.status,
      description: transaction.description,
      merchant: transaction.merchant,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'to_amount': toAmount,
        'to_currency': toCurrency,
        'status': status.name,
        'description': description,
        'merchant': merchant,
      };

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    return TransactionTemplate(
      id: json['id'] as String,
      name: json['name'] as String? ?? '未命名模板',
      type: TransactionType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      accountId: json['account_id'] as String,
      toAccountId: json['to_account_id'] as String?,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MYR',
      toAmount: (json['to_amount'] as num?)?.toDouble(),
      toCurrency: json['to_currency'] as String?,
      status: json['status'] == null
          ? TransactionStatus.actual
          : TransactionStatus.values.byName(json['status'] as String),
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
    );
  }
}

class RecurringTransactionRule {
  const RecurringTransactionRule({
    required this.id,
    required this.name,
    required this.type,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.startDate,
    this.intervalMonths = 1,
    this.status = TransactionStatus.actual,
    this.toAccountId,
    this.toAmount,
    this.toCurrency,
    this.categoryId,
    this.description,
    this.merchant,
    this.endDate,
    this.generatedMonthKeys = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final double amount;
  final String currency;
  final double? toAmount;
  final String? toCurrency;
  final DateTime startDate;
  final int intervalMonths;
  final TransactionStatus status;
  final String? description;
  final String? merchant;
  final DateTime? endDate;
  final List<String> generatedMonthKeys;
  final bool isActive;

  factory RecurringTransactionRule.fromTransaction({
    required String id,
    required String name,
    required FinanceTransaction transaction,
    int intervalMonths = 1,
  }) {
    return RecurringTransactionRule(
      id: id,
      name: name,
      type: transaction.type,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      currency: transaction.currency,
      toAmount: transaction.toAmount,
      toCurrency: transaction.toCurrency,
      startDate: transaction.transactionDate,
      intervalMonths: intervalMonths,
      status: transaction.status == TransactionStatus.planned
          ? TransactionStatus.actual
          : transaction.status,
      description: transaction.description,
      merchant: transaction.merchant,
    );
  }

  FinanceTransaction toTransaction({
    required String id,
    required DateTime date,
    required TransactionStatus status,
  }) {
    return FinanceTransaction(
      id: id,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      toAmount: toAmount,
      toCurrency: toCurrency,
      recordDate: date,
      transactionDate: date,
      status: status,
      recurringRuleId: this.id,
      description: description,
      merchant: merchant,
    );
  }

  RecurringTransactionRule copyWith({
    List<String>? generatedMonthKeys,
  }) {
    return RecurringTransactionRule(
      id: id,
      name: name,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      amount: amount,
      currency: currency,
      toAmount: toAmount,
      toCurrency: toCurrency,
      startDate: startDate,
      intervalMonths: intervalMonths,
      status: status,
      description: description,
      merchant: merchant,
      endDate: endDate,
      generatedMonthKeys: generatedMonthKeys ?? this.generatedMonthKeys,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'to_amount': toAmount,
        'to_currency': toCurrency,
        'start_date': startDate.toIso8601String(),
        'interval_months': intervalMonths,
        'status': status.name,
        'description': description,
        'merchant': merchant,
        'end_date': endDate?.toIso8601String(),
        'generated_month_keys': generatedMonthKeys,
        'is_active': isActive,
      };

  factory RecurringTransactionRule.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionRule(
      id: json['id'] as String,
      name: json['name'] as String? ?? '周期交易',
      type: TransactionType.values.byName(json['type'] as String),
      accountId: json['account_id'] as String,
      toAccountId: json['to_account_id'] as String?,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MYR',
      toAmount: (json['to_amount'] as num?)?.toDouble(),
      toCurrency: json['to_currency'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      intervalMonths: (json['interval_months'] as num?)?.toInt() ?? 1,
      status: json['status'] == null
          ? TransactionStatus.actual
          : TransactionStatus.values.byName(json['status'] as String),
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
      endDate: json['end_date'] == null
          ? null
          : DateTime.tryParse(json['end_date'] as String),
      generatedMonthKeys:
          (json['generated_month_keys'] as List<dynamic>? ?? const [])
              .map((item) => '$item')
              .toList(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CashFlowProjectionPoint {
  const CashFlowProjectionPoint({
    required this.monthKey,
    required this.income,
    required this.expense,
    required this.transfers,
    required this.net,
    required this.endingCash,
  });

  final String monthKey;
  final double income;
  final double expense;
  final double transfers;
  final double net;
  final double endingCash;
}

class CreditCardPaymentReminder {
  const CreditCardPaymentReminder({
    required this.account,
    required this.amountDue,
    required this.dueDate,
  });

  final Account account;
  final double amountDue;
  final DateTime dueDate;
}

class AssetGoalHistoryPoint {
  const AssetGoalHistoryPoint({
    required this.date,
    required this.label,
    required this.totalAssets,
  });

  final DateTime date;
  final String label;
  final double totalAssets;
}

class AssetGoal {
  const AssetGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.reachedAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final DateTime? reachedAt;

  AssetGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? reachedAt,
    bool clearReachedAt = false,
  }) {
    return AssetGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      reachedAt: clearReachedAt ? null : (reachedAt ?? this.reachedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'reached_at': reachedAt?.toIso8601String(),
      };

  factory AssetGoal.fromJson(Map<String, dynamic> json) {
    return AssetGoal(
      id: json['id'] as String,
      name: json['name'] as String? ?? '资产目标',
      targetAmount: (json['target_amount'] as num).toDouble(),
      reachedAt: json['reached_at'] == null
          ? null
          : DateTime.tryParse(json['reached_at'] as String),
    );
  }
}

class AssetGoalProgressSummary {
  const AssetGoalProgressSummary({
    required this.goal,
    required this.currentAssets,
    required this.reachedAt,
    required this.history,
  });

  final AssetGoal goal;
  final double currentAssets;
  final DateTime? reachedAt;
  final List<AssetGoalHistoryPoint> history;

  double get progressRatio {
    if (goal.targetAmount <= 0) {
      return 0;
    }
    return currentAssets / goal.targetAmount;
  }

  bool get isReached {
    return goal.targetAmount > 0 && currentAssets >= goal.targetAmount;
  }
}
