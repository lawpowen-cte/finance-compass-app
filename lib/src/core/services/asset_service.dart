import 'dart:convert';

import '../data/finance_repository.dart';
import '../database/app_database.dart' hide Account, AssetSnapshot;
import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/transaction.dart';
import '../utils/id_generator.dart';
import 'currency_service.dart';
import 'service_helpers.dart';

/// 资产快照管理、投资跟踪与资产目标服务。
///
/// 提供账户快照查询、成本基础计算、投资现金流汇总、
/// 资产目标追踪以及 CRUD 操作。
class AssetService {
  AssetService({
    required List<Account> accounts,
    required List<FinanceTransaction> transactions,
    required List<AssetSnapshot> snapshots,
    required Map<String, String> metaValues,
    required this.currencyService,
    required this.database,
  })  : _accounts = accounts,
        _transactions = transactions,
        _snapshots = snapshots,
        _metaValues = metaValues;

  final List<Account> _accounts;
  final List<FinanceTransaction> _transactions;
  final List<AssetSnapshot> _snapshots;
  final Map<String, String> _metaValues;
  final CurrencyService currencyService;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // 快照查询
  // ---------------------------------------------------------------------------

  /// 账户最新的资产快照。
  AssetSnapshot? latestSnapshotForAccount(String accountId) {
    final items = _snapshots
        .where((item) => item.accountId == accountId)
        .toList()
      ..sort((a, b) => b.snapshotDate.compareTo(a.snapshotDate));
    return items.isEmpty ? null : items.first;
  }

  /// 账户截至 [date] 的最新资产快照。
  AssetSnapshot? latestSnapshotForAccountUpTo(String accountId, DateTime date) {
    final items = _snapshots
        .where((item) =>
            item.accountId == accountId && !item.snapshotDate.isAfter(date))
        .toList()
      ..sort((a, b) => b.snapshotDate.compareTo(a.snapshotDate));
    return items.isEmpty ? null : items.first;
  }

  /// 账户所有快照（按日期升序）。
  List<AssetSnapshot> snapshotsForAccount(String accountId) {
    final items = _snapshots
        .where((item) => item.accountId == accountId)
        .toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    return items;
  }

  /// 账户截至 [date] 的所有快照（按日期升序）。
  List<AssetSnapshot> snapshotsForAccountUpTo(String accountId, DateTime date) {
    final items = _snapshots
        .where((item) =>
            item.accountId == accountId && !item.snapshotDate.isAfter(date))
        .toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));
    return items;
  }

  /// 账户最早的一条快照。
  AssetSnapshot? firstSnapshotForAccount(String accountId) {
    final items = snapshotsForAccount(accountId);
    return items.isEmpty ? null : items.first;
  }

  // ---------------------------------------------------------------------------
  // 投资现金流
  // ---------------------------------------------------------------------------

  /// 账户在指定时间范围内的投资流入/流出汇总。
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

  // ---------------------------------------------------------------------------
  // 成本基础
  // ---------------------------------------------------------------------------

  /// 账户截至 [upToDate] 的累计成本基础。
  double costBasisForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final targetDate = upToDate ?? _currentMonthCutoffDate();
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

  /// 指定快照对应时间点的成本基础。
  double snapshotCostBasis(AssetSnapshot snapshot) {
    return costBasisForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
  }

  /// 账户截至 [upToDate] 的现金余额。
  double cashBalanceForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final targetDate = upToDate ?? _currentMonthCutoffDate();
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

  /// 账户截至 [upToDate] 的剩余成本基础。
  double remainingCostBasisForAccount(
    String accountId, {
    DateTime? upToDate,
  }) {
    final targetDate = upToDate ?? _currentMonthCutoffDate();
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

  /// 指定快照对应时间点的剩余成本基础。
  double snapshotRemainingCostBasis(AssetSnapshot snapshot) {
    return remainingCostBasisForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
  }

  /// 快照未实现盈亏。
  double snapshotUnrealizedPnl(AssetSnapshot snapshot) {
    return snapshot.marketValue - snapshotRemainingCostBasis(snapshot);
  }

  /// 快照盈亏比例。
  double snapshotPnlRatio(AssetSnapshot snapshot) {
    final costBasis = snapshotRemainingCostBasis(snapshot);
    if (costBasis == 0) {
      return 0;
    }
    return snapshotUnrealizedPnl(snapshot) / costBasis;
  }

  // ---------------------------------------------------------------------------
  // 资产目标
  // ---------------------------------------------------------------------------

  /// 所有资产目标（按目标金额排序）。
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

    // 兼容旧版单一目标格式
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
        name: '净资产目标',
        targetAmount: legacyAmount,
        reachedAt: legacyReachedAtRaw == null
            ? null
            : DateTime.tryParse(legacyReachedAtRaw),
      ),
    ];
  }

  /// 净资产历史走势（按月）。
  List<AssetGoalHistoryPoint> totalAssetHistory({
    DateTime? cutoffDate,
  }) {
    final targetCutoff = cutoffDate ?? _currentMonthCutoffDate();
    final monthKeys = <String>{
      serviceMonthKey(targetCutoff),
      ..._transactions
          .where((item) => !item.transactionDate.isAfter(targetCutoff))
          .map((item) => serviceMonthKey(item.transactionDate)),
      ..._snapshots
          .where((item) => !item.snapshotDate.isAfter(targetCutoff))
          .map((item) => serviceMonthKey(item.snapshotDate)),
    }.toList()
      ..sort(compareMonthKeys);

    if (monthKeys.isEmpty) {
      final now = DateTime.now();
      return [
        AssetGoalHistoryPoint(
          date: now,
          label: '${now.year}-${now.month.toString().padLeft(2, '0')}',
          totalAssets: _totalTargetAssets(targetCutoff),
        ),
      ];
    }

    return monthKeys.map((monthKey) {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final isCutoffMonth = monthKey == serviceMonthKey(targetCutoff);
      final date = isCutoffMonth ? targetCutoff : DateTime(year, month + 1, 0);
      return AssetGoalHistoryPoint(
        date: date,
        label: monthKey,
        totalAssets: _totalAssetsAt(date),
      );
    }).toList();
  }

  /// 各资产目标的进度摘要。
  List<AssetGoalProgressSummary> assetGoalSummaries({
    DateTime? cutoffDate,
  }) {
    final targetCutoff = cutoffDate ?? _currentMonthCutoffDate();
    final history = totalAssetHistory(cutoffDate: targetCutoff);
    final currentAssets = _totalAssetsAt(targetCutoff);
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

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addAssetSnapshot(AssetSnapshot snapshot) async {
    await database.insertAssetSnapshot(snapshot);
  }

  Future<void> updateAssetSnapshot(AssetSnapshot snapshot) async {
    await database.updateAssetSnapshot(snapshot);
  }

  Future<void> deleteAssetSnapshot(String snapshotId) async {
    await database.deleteAssetSnapshot(snapshotId);
  }

  Future<void> addAssetGoal({
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
  }

  Future<void> updateAssetGoal(AssetGoal goal) async {
    final nextGoals =
        assetGoals.map((item) => item.id == goal.id ? goal : item).toList();
    await _saveAssetGoals(nextGoals);
  }

  Future<void> deleteAssetGoal(String goalId) async {
    final nextGoals = assetGoals.where((item) => item.id != goalId).toList();
    await _saveAssetGoals(nextGoals);
  }

  /// 同步资产目标的到达时间。
  Future<void> syncAssetGoalReachedAt() async {
    if (assetGoals.isEmpty) {
      await database.deleteMetaValue('asset_goals_json');
      await database.deleteMetaValue('asset_goal_amount');
      await database.deleteMetaValue('asset_goal_reached_at');
      return;
    }
    final syncedGoals =
        assetGoalSummaries(cutoffDate: _currentMonthCutoffDate())
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

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  DateTime _currentMonthCutoffDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  double _totalTargetAssets(DateTime cutoffDate) {
    return _totalAssetsAt(cutoffDate);
  }

  double _totalAssetsAt(DateTime date, {bool includeCredit = true}) {
    return _accounts
        .where((account) =>
            includeCredit || account.reportGroup != ReportGroup.credit)
        .fold(
          0.0,
          (sum, account) =>
              sum +
              currencyService.convertToBase(
                  _accountBalanceAt(account, date), account.currency),
        );
  }

  /// 计算账户在 [date] 的余额（账户原币）。
  double _accountBalanceAt(Account account, DateTime date) {
    final accountSnapshots = _snapshots
        .where((s) => s.accountId == account.id)
        .toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

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
}
