import '../database/app_database.dart'
    hide Budget, Category;
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/month_key.dart';
import 'currency_service.dart';
import 'service_helpers.dart';

/// 预算 CRUD、跨月结转与预算金额计算服务。
///
/// 提供活跃预算查询、有效预算（含结转）计算、
/// 预算内支出汇总等功能。
class BudgetService {
  BudgetService({
    required List<Budget> budgets,
    required List<FinanceTransaction> transactions,
    required List<Category> categories,
    required this.currencyService,
    required this.database,
  })  : _budgets = budgets,
        _transactions = transactions,
        _categories = categories;

  final List<Budget> _budgets;
  final List<FinanceTransaction> _transactions;
  final List<Category> _categories;
  final CurrencyService currencyService;
  final AppDatabase database;

  // ---------------------------------------------------------------------------
  // 查询
  // ---------------------------------------------------------------------------

  /// 所有预算（按分类名、月份倒序排列）。
  List<Budget> reusableBudgets() {
    final items = [..._budgets]..sort((a, b) {
        final categoryCompare =
            _categoryName(a.categoryId).compareTo(_categoryName(b.categoryId));
        if (categoryCompare != 0) {
          return categoryCompare;
        }
        return compareMonthKeys(b.monthKey, a.monthKey);
      });
    return items;
  }

  /// 指定月份的活跃预算（每个分类取 ≤ [monthKey] 的最新预算）。
  List<Budget> activeBudgetsForMonth(String monthKey) {
    final latestByCategory = <String, Budget>{};
    for (final budget in _budgets) {
      if (compareMonthKeys(budget.monthKey, monthKey) > 0) {
        continue;
      }
      final existing = latestByCategory[budget.categoryId];
      if (existing == null ||
          compareMonthKeys(budget.monthKey, existing.monthKey) > 0) {
        latestByCategory[budget.categoryId] = budget;
      }
    }
    final items = latestByCategory.values.toList()
      ..sort((a, b) =>
          _categoryName(a.categoryId).compareTo(_categoryName(b.categoryId)));
    return items;
  }

  /// 可选的预算月份键列表（当前月 + 有交易/预算的月 + 未来 [futureMonths] 月）。
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
      ..sort((a, b) => compareMonthKeys(b, a));
    return monthKeys;
  }

  /// 预算总额（基准货币），可按 [monthKey] 筛选。
  double totalBudgetAmount({String? monthKey}) {
    final items = monthKey == null ? _budgets : activeBudgetsForMonth(monthKey);
    return items.fold(0, (sum, item) => sum + budgetAmountInBase(item));
  }

  /// 单个预算的基准货币金额。
  double budgetAmountInBase(Budget budget) {
    return currencyService.convertToBase(budget.amount, budget.currency);
  }

  // ---------------------------------------------------------------------------
  // 预算内支出
  // ---------------------------------------------------------------------------

  /// 指定月份已预算分类的实际支出合计（基准货币）。
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
              serviceMonthKey(item.transactionDate) == monthKey,
        )
        .fold(0, (sum, item) => sum + _transactionAmountInBase(item));
  }

  /// 指定月份已预算分类的计划支出合计（基准货币）。
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
              serviceMonthKey(item.transactionDate) == monthKey,
        )
        .fold(0, (sum, item) => sum + _transactionAmountInBase(item));
  }

  /// 指定分类在指定月份的实际支出（基准货币）。
  double expenseTotalForCategory(String categoryId, String monthKey) {
    return _transactions
        .where((transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.status != TransactionStatus.planned &&
            transaction.categoryId == categoryId &&
            serviceMonthKey(transaction.transactionDate) == monthKey)
        .fold(0,
            (sum, transaction) => sum + _transactionAmountInBase(transaction));
  }

  /// 指定分类在指定月份的计划支出（基准货币）。
  double plannedExpenseTotalForCategory(String categoryId, String monthKey) {
    return _transactions
        .where((transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.status == TransactionStatus.planned &&
            transaction.categoryId == categoryId &&
            serviceMonthKey(transaction.transactionDate) == monthKey)
        .fold(0,
            (sum, transaction) => sum + _transactionAmountInBase(transaction));
  }

  // ---------------------------------------------------------------------------
  // 有效预算（含结转）
  // ---------------------------------------------------------------------------

  /// 指定预算在 [monthKey] 的有效金额（含结转累积）。
  ///
  /// 若 [monthKey] 早于预算生效月则返回 0；
  /// 遍历从预算首月到 [monthKey] 的所有月份，
  /// 若某月有新预算则替换基准，若开启结转则累积剩余。
  double effectiveBudgetForMonth(Budget budget, String monthKey) {
    if (compareMonthKeys(monthKey, budget.monthKey) < 0) {
      return 0;
    }

    final categoryBudgets = _budgets
        .where((item) => item.categoryId == budget.categoryId)
        .toList()
      ..sort((a, b) => compareMonthKeys(a.monthKey, b.monthKey));
    if (categoryBudgets.isEmpty) {
      return 0;
    }

    final firstBudget = categoryBudgets.first;
    var carry = 0.0;
    for (final currentMonthKey
        in monthKeyRange(firstBudget.monthKey, monthKey)) {
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

  /// 指定月份所有活跃预算的有效金额合计（基准货币）。
  double totalEffectiveBudgetForMonth(String monthKey) {
    return activeBudgetsForMonth(monthKey)
        .fold(0, (sum, item) => sum + effectiveBudgetForMonth(item, monthKey));
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addBudget(Budget budget) async {
    await database.upsertBudget(budget);
  }

  Future<void> deleteBudget(String budgetId) async {
    await database.deleteBudget(budgetId);
  }

  // ---------------------------------------------------------------------------
  // 私有辅助
  // ---------------------------------------------------------------------------

  double _transactionAmountInBase(FinanceTransaction transaction) {
    return currencyService.convertToBase(
        transaction.amount, transaction.currency);
  }

  Budget? _budgetForCategoryInMonth(String categoryId, String monthKey) {
    Budget? latest;
    for (final budget
        in _budgets.where((item) => item.categoryId == categoryId)) {
      if (compareMonthKeys(budget.monthKey, monthKey) > 0) {
        continue;
      }
      if (latest == null ||
          compareMonthKeys(budget.monthKey, latest.monthKey) > 0) {
        latest = budget;
      }
    }
    return latest;
  }

  String _categoryName(String categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return '未命名类别';
  }
}
