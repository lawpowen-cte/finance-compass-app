import '../data/finance_repository.dart';
import '../database/app_database.dart' hide Account, AssetSnapshot;
import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/transaction.dart';

import 'currency_service.dart';
import 'service_helpers.dart';

/// 账户余额计算、分组查询与对账管理服务。
///
/// 提供按账户/报告分组统计资产、计算任意时间点余额、
/// 余额追踪以及对账状态管理等功能。
class AccountService {
  AccountService({
    required List<Account> accounts,
    required List<FinanceTransaction> transactions,
    required List<AssetSnapshot> snapshots,
    required this.currencyService,
    required this.database,
  })  : _accounts = accounts,
        _transactions = transactions,
        _snapshots = snapshots;

  final List<Account> _accounts;
  final List<FinanceTransaction> _transactions;
  final List<AssetSnapshot> _snapshots;
  final CurrencyService currencyService;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // 通用
  // ---------------------------------------------------------------------------

  /// 当月最后一天 23:59:59.999，用作统计截止时间。
  DateTime currentMonthCutoffDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 按 [ReportGroup] 筛选账户。
  List<Account> accountsByGroup(ReportGroup group) {
    return _accounts.where((item) => item.reportGroup == group).toList();
  }

  /// 所有投资类账户（[ReportGroup.investment] 或 [ReportGroup.retirement]）。
  List<Account> investmentAccounts() {
    return _accounts
        .where(
          (item) =>
              item.reportGroup == ReportGroup.investment ||
              item.reportGroup == ReportGroup.retirement,
        )
        .toList();
  }

  String accountName(String accountId) {
    return _accounts.firstWhere((item) => item.id == accountId).name;
  }

  // ---------------------------------------------------------------------------
  // 资产汇总
  // ---------------------------------------------------------------------------

  /// 截至当月末的指定 [group] 资产（基准货币）。
  double totalAssetsByGroup(ReportGroup group) {
    return displayTotalAssetsByGroup(group,
        cutoffDate: currentMonthCutoffDate());
  }

  /// 截至 [cutoffDate]（默认当月末）的指定 [group] 资产（基准货币）。
  double displayTotalAssetsByGroup(ReportGroup group, {DateTime? cutoffDate}) {
    final targetDate = cutoffDate ?? currentMonthCutoffDate();
    return _accounts.where((account) => account.reportGroup == group).fold(
          0.0,
          (sum, account) => accountBalanceAtBase(account.id, targetDate),
        );
  }

  /// 截至当月末的总资产（基准货币）。
  double totalAssets({bool includeCredit = true}) {
    return displayTotalAssets(
      includeCredit: includeCredit,
      cutoffDate: currentMonthCutoffDate(),
    );
  }

  /// 截至 [cutoffDate]（默认当月末）的总资产（基准货币）。
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

  /// 目标资产（包含信用卡/负债后的净资产）。
  double totalTargetAssets() {
    return displayTotalAssets(
      includeCredit: true,
      cutoffDate: currentMonthCutoffDate(),
    );
  }

  /// 截至 [date] 的总资产（基准货币）。
  double totalAssetsAt(DateTime date, {bool includeCredit = true}) {
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

  // ---------------------------------------------------------------------------
  // 账户余额（单个账户）
  // ---------------------------------------------------------------------------

  /// 账户在 [date] 的余额（账户原币）。
  double accountBalanceAt(String accountId, DateTime date) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    return _accountBalanceAt(account, date);
  }

  /// 账户在 [date] 的余额（基准货币）。
  double accountBalanceAtBase(String accountId, DateTime date) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    return currencyService.convertToBase(
        _accountBalanceAt(account, date), account.currency);
  }

  /// 单笔交易对指定账户的余额影响（账户原币）。
  double transactionDeltaForAccount(
    String accountId,
    FinanceTransaction transaction,
  ) {
    return _transactionDeltaForAccount(accountId, transaction);
  }

  // ---------------------------------------------------------------------------
  // 余额追踪
  // ---------------------------------------------------------------------------

  /// 从 [cutoffDate] 向前追溯账户余额变化过程。
  AccountBalanceTrace accountBalanceTrace(
    String accountId,
    DateTime cutoffDate,
  ) {
    final account = _accounts.firstWhere((item) => item.id == accountId);
    final accountSnapshots = _snapshots
        .where((s) => s.accountId == accountId)
        .toList()
      ..sort((a, b) => a.snapshotDate.compareTo(b.snapshotDate));

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

  // ---------------------------------------------------------------------------
  // 对账
  // ---------------------------------------------------------------------------

  /// 获取账户最近对账月份。
  String? reconciledMonthForAccount(String accountId) {
    // 由调用方（Repository）从 metaValues 中读取
    return null; // 实际由 Repository 层代理
  }

  /// 判断账户在 [monthKey] 及之前是否已对账。
  bool isAccountReconciledForMonth(
    String accountId,
    String? reconciledMonth,
    String monthKey,
  ) {
    if (reconciledMonth == null) {
      return false;
    }
    return compareMonthKeys(reconciledMonth, monthKey) >= 0;
  }

  /// 持久化账户对账月份。
  Future<void> setAccountReconciledMonth(
    String accountId,
    String monthKey,
  ) async {
    await database.setMetaValue(
      _accountReconciliationKey(accountId),
      monthKey,
    );
  }

  /// 清除账户对账记录。
  Future<void> clearAccountReconciledMonth(String accountId) async {
    await database.deleteMetaValue(_accountReconciliationKey(accountId));
  }

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  String _accountReconciliationKey(String accountId) {
    return 'account_reconciled_month_$accountId';
  }

  /// 计算账户在 [date] 的余额（账户原币）。
  ///
  /// 优先使用最近快照，然后叠加其后交易影响；
  /// 若无快照，则从当前余额反向扣除。
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

  /// 单笔交易对指定账户的余额影响。
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
    // 该方法仅用于 trace 显示，完整分类名需通过外部注入；
    // 此处使用简化 fallback，Repository 层会覆盖。
    for (final _ in []) {
      // placeholder
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
}
