import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/finance_repository.dart';
import '../database/app_database.dart'
    hide Account, AssetSnapshot, Budget, Category;
import '../models/account.dart';
import '../models/asset_snapshot.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/month_key.dart';
import 'account_service.dart';
import 'budget_service.dart';
import 'currency_service.dart';
import 'report_service.dart';
import 'service_helpers.dart';

/// JSON 导入/导出、AI 摘要与 CSV 导出服务。
///
/// 提供完整的数据快照导出、AI 友好的摘要 JSON、
/// 未来规划 CSV 以及 JSON 数据导入功能。
class ExportService {
  ExportService({
    required List<Account> accounts,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<FinanceTransaction> transactions,
    required List<AssetSnapshot> snapshots,
    required this.currencyService,
    required this.accountService,
    required this.budgetService,
    required this.reportService,
    required this.database,
  })  : _accounts = accounts,
        _categories = categories,
        _budgets = budgets,
        _transactions = transactions,
        _snapshots = snapshots;

  final List<Account> _accounts;
  final List<Category> _categories;
  final List<Budget> _budgets;
  final List<FinanceTransaction> _transactions;
  final List<AssetSnapshot> _snapshots;
  final CurrencyService currencyService;
  final AccountService accountService;
  final BudgetService budgetService;
  final ReportService reportService;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // JSON 快照导出
  // ---------------------------------------------------------------------------

  /// 构建完整的 JSON 导出数据结构。
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

  /// 导出 JSON 快照字节流。
  Future<Uint8List> exportJsonSnapshotBytes() async {
    final payload = await buildJsonSnapshotPayload();
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  /// 导出 JSON 快照文件，返回文件路径。
  Future<String> exportJsonSnapshot([String? targetPath]) async {
    final file = File(targetPath ?? await _defaultExportPath());
    final payload = await buildJsonSnapshotPayload();
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // JSON 导入
  // ---------------------------------------------------------------------------

  /// 导入 JSON 快照，替换所有数据。
  Future<void> importJsonSnapshot(String path) async {
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
  }

  /// 预览 JSON 导入文件的内容摘要。
  Future<ImportPreview> previewImportJson(String path) async {
    final file = File(path);
    final raw = await file.readAsString();
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    return ImportPreview(
      accounts: (payload['accounts'] as List<dynamic>? ?? const []).length,
      categories:
          (payload['categories'] as List<dynamic>? ?? const []).length,
      budgets: (payload['budgets'] as List<dynamic>? ?? const []).length,
      transactions:
          (payload['transactions'] as List<dynamic>? ?? const []).length,
      assetSnapshots:
          (payload['asset_snapshots'] as List<dynamic>? ?? const []).length,
      exportedAt: payload['exported_at'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // AI 摘要
  // ---------------------------------------------------------------------------

  /// 构建 AI 友好的摘要数据（按月汇总收支、分类明细、资产、预算）。
  Map<String, dynamic> buildAiSummaryPayload({
    required List<String> monthKeys,
  }) {
    final includedMonths = monthKeys.where((monthKey) {
      return reportService.totalIncomeForMonth(monthKey) != 0 ||
          reportService.totalExpenseForMonth(monthKey) != 0 ||
          reportService.plannedIncomeForMonth(monthKey) != 0 ||
          reportService.plannedExpenseForMonth(monthKey) != 0;
    }).toList();
    final currentMonth = monthKeyFromDate(DateTime.now());
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'base_currency': currencyService.baseCurrency,
      'currency_priority': currencyService.currencyPriority,
      'exchange_rates_to_base': currencyService.exchangeRatesToBase,
      'months': includedMonths,
      'income_by_month': {
        for (final monthKey in includedMonths)
          monthKey: reportService.totalIncomeForMonth(monthKey),
      },
      'expense_by_month': {
        for (final monthKey in includedMonths)
          monthKey: reportService.totalExpenseForMonth(monthKey),
      },
      'planned_income_by_month': {
        for (final monthKey in includedMonths)
          monthKey: reportService.plannedIncomeForMonth(monthKey),
      },
      'planned_expense_by_month': {
        for (final monthKey in includedMonths)
          monthKey: reportService.plannedExpenseForMonth(monthKey),
      },
      'net_by_month': {
        for (final monthKey in includedMonths)
          monthKey: reportService.totalIncomeForMonth(monthKey) -
              reportService.totalExpenseForMonth(monthKey),
      },
      'expense_categories_by_month': {
        for (final monthKey in includedMonths)
          monthKey: {
            for (final entry in reportService
                .categoryTotalsForMonths(
                  type: CategoryType.expense,
                  monthKeys: [monthKey],
                )
                .entries)
              _categoryName(entry.key): entry.value,
          },
      },
      'income_categories_by_month': {
        for (final monthKey in includedMonths)
          monthKey: {
            for (final entry in reportService
                .categoryTotalsForMonths(
                  type: CategoryType.income,
                  monthKeys: [monthKey],
                )
                .entries)
              _categoryName(entry.key): entry.value,
          },
      },
      'expense_category_totals': {
        for (final entry in reportService
            .categoryTotalsForMonths(
              type: CategoryType.expense,
              monthKeys: includedMonths,
            )
            .entries)
          _categoryName(entry.key): entry.value,
      },
      'income_category_totals': {
        for (final entry in reportService
            .categoryTotalsForMonths(
              type: CategoryType.income,
              monthKeys: includedMonths,
            )
            .entries)
          _categoryName(entry.key): entry.value,
      },
      'assets_by_group': {
        'cash': accountService.totalAssetsByGroup(ReportGroup.cash),
        'credit': accountService.totalAssetsByGroup(ReportGroup.credit),
        'investment': accountService.totalAssetsByGroup(ReportGroup.investment),
        'retirement': accountService.totalAssetsByGroup(ReportGroup.retirement),
      },
      'budgets_current_month': {
        for (final budget in budgetService.activeBudgetsForMonth(currentMonth))
          _categoryName(budget.categoryId): {
            'budget':
                budgetService.effectiveBudgetForMonth(budget, currentMonth),
            'spent': budgetService.expenseTotalForCategory(
                budget.categoryId, currentMonth),
          },
      },
    };
  }

  /// AI 摘要 JSON 字节流。
  Uint8List exportAiSummaryBytes({required List<String> monthKeys}) {
    return Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(
          buildAiSummaryPayload(monthKeys: monthKeys),
        ),
      ),
    );
  }

  /// 导出 AI 摘要 JSON 文件。
  Future<String> exportAiSummaryJson(String targetPath,
      {required List<String> monthKeys}) async {
    final payload = buildAiSummaryPayload(monthKeys: monthKeys);
    final file = File(targetPath);
    await file
        .writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // CSV 导出
  // ---------------------------------------------------------------------------

  /// 导出未来规划 CSV 字节流。
  Uint8List exportFuturePlanningCsvBytes({int months = 24}) {
    final now = DateTime.now();
    final monthKeys = List.generate(
      months,
      (index) => monthKeyFromDate(DateTime(now.year, now.month + index + 1)),
    );

    final categoryIds = <String>{
      ..._categories
          .where((c) => c.type == CategoryType.expense)
          .map((item) => item.id),
    }.where((categoryId) {
      final hasBudget = _budgets.any((item) => item.categoryId == categoryId);
      final hasFutureExpense = monthKeys.any(
        (monthKey) =>
            budgetService.expenseTotalForCategory(categoryId, monthKey) != 0 ||
            budgetService.plannedExpenseTotalForCategory(
                    categoryId, monthKey) !=
                0,
      );
      return hasBudget || hasFutureExpense;
    }).toList()
      ..sort((a, b) => _categoryName(a).compareTo(_categoryName(b)));

    final lines = <List<String>>[];
    lines.add([
      'Category',
      'Base Budget',
      ...monthKeys,
      'Planned Total',
    ]);

    for (final categoryId in categoryIds) {
      final budgetList = _budgets
          .where((item) => item.categoryId == categoryId)
          .toList()
        ..sort((a, b) => compareMonthKeys(b.monthKey, a.monthKey));
      final baseBudget =
          budgetList.isEmpty ? 0.0 : budgetService.budgetAmountInBase(budgetList.first);
      final monthValues = monthKeys
          .map((monthKey) =>
              budgetService.expenseTotalForCategory(categoryId, monthKey) +
              budgetService.plannedExpenseTotalForCategory(
                  categoryId, monthKey))
          .toList();
      final plannedTotal =
          monthValues.fold<double>(0, (sum, item) => sum + item);
      lines.add([
        _categoryName(categoryId),
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
                budgetService.expenseTotalForCategory(categoryId, monthKey) +
                budgetService.plannedExpenseTotalForCategory(
                    categoryId, monthKey),
          ),
        )
        .toList();
    final monthlyBudgets = monthKeys
        .map(
          (monthKey) => budgetService
              .activeBudgetsForMonth(monthKey)
              .fold<double>(
                0,
                (sum, budget) =>
                    sum +
                    budgetService.effectiveBudgetForMonth(budget, monthKey),
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

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  Future<String> _defaultExportPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return p.join(directory.path, 'finance_compass_export_$timestamp.json');
  }

  String _categoryName(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return '未命名类别';
  }

  String _csvMoney(double value) => value == 0 ? '' : value.toStringAsFixed(2);

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
