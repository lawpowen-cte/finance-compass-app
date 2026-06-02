import 'dart:convert';

import '../data/finance_repository.dart';
import '../database/app_database.dart'
    hide Account, Category;

import '../models/transaction.dart';
import '../utils/id_generator.dart';
import 'currency_service.dart';
import 'service_helpers.dart';

/// 交易记录查询、模板管理与周期交易规则服务。
///
/// 提供按时间/分类筛选交易、管理交易模板、
/// 生成周期性交易等业务逻辑。
class TransactionService {
  TransactionService({
    required List<FinanceTransaction> transactions,
    required Map<String, String> metaValues,
    required this.currencyService,
    required this.database,
  })  : _transactions = transactions,
        _metaValues = metaValues;

  final List<FinanceTransaction> _transactions;
  final Map<String, String> _metaValues;
  final CurrencyService currencyService;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 最近 [limit] 条交易（按日期倒序）。
  List<FinanceTransaction> recentTransactions({int limit = 5}) {
    final items = [..._transactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return items.take(limit).toList();
  }

  /// 即将到来的支出交易（从明天起，最多 [limit] 条）。
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

  /// 未来 [monthsAhead] 个月的总支出（基准货币）。
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
        .fold(0, (sum, item) => sum + _transactionAmountInBase(item));
  }

  /// 按分类筛选交易。
  List<FinanceTransaction> transactionsForCategory(
    String categoryId, {
    String? monthKey,
  }) {
    final items = _transactions.where((item) => item.categoryId == categoryId);
    final filtered = monthKey == null
        ? items
        : items
            .where((item) => serviceMonthKey(item.transactionDate) == monthKey);
    final list = filtered.toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  /// 指定账户在指定月份的支出分分类汇总（账户原币）。
  Map<String, double> expenseBreakdownForAccount(
      String accountId, String monthKey) {
    final map = <String, double>{};

    for (final transaction in _transactions.where((item) =>
        item.accountId == accountId &&
        item.type == TransactionType.expense &&
        item.status != TransactionStatus.planned &&
        serviceMonthKey(item.transactionDate) == monthKey)) {
      final key = transaction.categoryId ?? 'uncategorized';
      map[key] = (map[key] ?? 0) + transaction.amount;
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // 交易模板
  // ---------------------------------------------------------------------------

  /// 所有已保存的交易模板（按名称排序）。
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

  /// 保存新交易模板（覆盖同名模板）。
  Future<void> addTransactionTemplate({
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
  }

  /// 删除交易模板。
  Future<void> deleteTransactionTemplate(String templateId) async {
    await _saveTransactionTemplates(
      transactionTemplates.where((item) => item.id != templateId).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 周期交易规则
  // ---------------------------------------------------------------------------

  /// 所有周期交易规则（按名称排序）。
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

  /// 新增周期交易规则（覆盖同名规则）。
  Future<void> addRecurringTransactionRule({
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
  }

  /// 删除周期交易规则。
  Future<void> deleteRecurringTransactionRule(String ruleId) async {
    await _saveRecurringTransactionRules(
      recurringTransactionRules.where((item) => item.id != ruleId).toList(),
    );
  }

  /// 根据周期规则生成未来 [monthsAhead] 个月的交易记录。
  ///
  /// 返回本次新增的交易列表（供调用方批量插入数据库）。
  List<FinanceTransaction> buildRecurringTransactions(
    RecurringTransactionRule rule, {
    int monthsAhead = 6,
  }) {
    if (!rule.isActive) {
      return const [];
    }

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + monthsAhead, now.day);
    final generatedKeys = {...rule.generatedMonthKeys};
    final transactions = <FinanceTransaction>[];
    var generatedCount = 0;
    var cursor = DateTime(
      rule.startDate.year,
      rule.startDate.month,
      rule.startDate.day,
    );

    while (!cursor.isAfter(endDate)) {
      final currentMonthKey = serviceMonthKey(cursor);
      if (!generatedKeys.contains(currentMonthKey) &&
          (rule.endDate == null || !cursor.isAfter(rule.endDate!))) {
        final isFuture = cursor.isAfter(DateTime(now.year, now.month, now.day));
        transactions.add(
          rule.toTransaction(
            id: '${buildId('txn')}_${generatedCount++}',
            date: cursor,
            status: isFuture ? TransactionStatus.planned : rule.status,
          ),
        );
        generatedKeys.add(currentMonthKey);
      }
      cursor = DateTime(
        cursor.year,
        cursor.month + rule.intervalMonths,
        cursor.day,
      );
    }

    return transactions;
  }

  // ---------------------------------------------------------------------------
  // CRUD（数据库操作）
  // ---------------------------------------------------------------------------

  Future<void> addTransaction(FinanceTransaction transaction) async {
    await database.insertTransaction(transaction);
  }

  Future<void> addTransactions(List<FinanceTransaction> transactions) async {
    if (transactions.isEmpty) return;
    await database.insertTransactions(transactions);
  }

  Future<void> updateTransaction(FinanceTransaction transaction) async {
    await database.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await database.deleteTransaction(transactionId);
  }

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  double _transactionAmountInBase(FinanceTransaction transaction) {
    return currencyService.convertToBase(
        transaction.amount, transaction.currency);
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
}
