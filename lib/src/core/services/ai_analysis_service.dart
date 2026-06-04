import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/finance_repository.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/month_key.dart';
import '../utils/month_range.dart';

class AiAnalysisService {
  final String gatewayUrl;

  AiAnalysisService({
    required this.gatewayUrl,
  });

  Future<String> generateAnalysis(
    FinanceRepository repository, {
    bool includePlanned = false,
    int monthCount = 6,
  }) async {
    final data = _buildRequestData(repository,
        includePlanned: includePlanned, monthCount: monthCount);
    final uri = Uri.parse('$gatewayUrl/api/analyze');

    const maxRetries = 2;
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'data': data}),
            )
            .timeout(const Duration(seconds: 300));

        if (response.statusCode != 200) {
          throw Exception('Gateway 返回 ${response.statusCode}: ${response.body}');
        }

        final result = jsonDecode(response.body);
        return result['summary'] as String;
      } on TimeoutException {
        lastError = Exception('请求超时（300秒）');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        }
      }
    }

    throw AiNetworkException(
      '无法连接到 AI 网关\n\n'
      '请检查：\n'
      '1. 网关服务器是否运行中\n'
      '2. 手机网络是否正常\n'
      '3. 网关地址是否正确',
      originalError: lastError,
    );
  }

  Map<String, dynamic> _buildRequestData(
    FinanceRepository repository, {
    required bool includePlanned,
    required int monthCount,
  }) {
    final now = DateTime.now();
    final currentMonth = monthKeyFromDate(now);
    final lastMonth = monthKeyFromDate(DateTime(now.year, now.month - 1));
    final monthKeys = recentMonthKeys(count: monthCount, anchor: now);

    // Account summary (用 base currency)
    final accounts = <Map<String, dynamic>>[];
    for (final group in ReportGroup.values) {
      for (final acc in repository.accountsByGroup(group)) {
        final balance = repository.accountBalanceAtBase(acc.id, now);
        accounts.add({
          'name': acc.name,
          'type': acc.accountType.name,
          'balance': balance,
        });
      }
    }

    // Monthly summary
    final income = repository.totalIncomeForMonth(currentMonth);
    final expense = repository.totalExpenseForMonth(currentMonth);
    final lastIncome = repository.totalIncomeForMonth(lastMonth);
    final lastExpense = repository.totalExpenseForMonth(lastMonth);

    // 计算 actual 和 planned
    final plannedIncome = repository.plannedIncomeForMonth(currentMonth);
    final plannedExpense = repository.plannedExpenseForMonth(currentMonth);

    // 根据用户选择确定主要数据
    final displayIncome = includePlanned ? income + plannedIncome : income;
    final displayExpense = includePlanned ? expense + plannedExpense : expense;

    // 支出分类明细（近N个月）
    final expenseByCategory = repository.categoryTotalsForMonths(
      type: CategoryType.expense,
      monthKeys: monthKeys,
    );
    final expenseCategories = <Map<String, dynamic>>[];
    for (final entry in expenseByCategory.entries) {
      if (entry.value > 0) {
        expenseCategories.add({
          'name': repository.categoryName(entry.key),
          'total': entry.value,
          'monthly_avg': entry.value / monthCount,
        });
      }
    }
    expenseCategories.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    // 收入分类明细（近N个月）
    final incomeByCategory = repository.categoryTotalsForMonths(
      type: CategoryType.income,
      monthKeys: monthKeys,
    );
    final incomeCategories = <Map<String, dynamic>>[];
    for (final entry in incomeByCategory.entries) {
      if (entry.value > 0) {
        incomeCategories.add({
          'name': repository.categoryName(entry.key),
          'total': entry.value,
          'monthly_avg': entry.value / monthCount,
        });
      }
    }
    incomeCategories.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    // Budgets
    final budgets = <Map<String, dynamic>>[];
    for (final b in repository.activeBudgetsForMonth(currentMonth)) {
      final effective = repository.effectiveBudgetForMonth(b, currentMonth);
      final spent = repository.expenseTotalForCategory(b.categoryId, currentMonth);
      final catName = repository.categoryName(b.categoryId);
      budgets.add({
        'category': catName,
        'budget': effective,
        'spent': spent,
      });
    }

    // Goals
    final goals = <Map<String, dynamic>>[];
    for (final g in repository.assetGoalSummaries()) {
      final progress = (g.progressRatio * 100).toStringAsFixed(1);
      goals.add({
        'name': g.goal.name,
        'target': g.goal.targetAmount,
        'current': g.currentAssets,
        'progress': progress,
        'is_reached': g.isReached,
      });
    }

    // 近N个月趋势（根据 includePlanned 决定用哪种数据）
    final recentMonths = <Map<String, dynamic>>[];
    for (int i = monthCount - 1; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i);
      final mKey = monthKeyFromDate(mDate);
      final mIncome = repository.totalIncomeForMonth(mKey) +
          (includePlanned ? repository.plannedIncomeForMonth(mKey) : 0);
      final mExpense = repository.totalExpenseForMonth(mKey) +
          (includePlanned ? repository.plannedExpenseForMonth(mKey) : 0);
      if (mIncome > 0 || mExpense > 0) {
        recentMonths.add({
          'month': mKey,
          'income': mIncome,
          'expense': mExpense,
          'net': mIncome - mExpense,
        });
      }
    }

    return {
      'base_currency': repository.baseCurrency,
      'data_mode': includePlanned ? 'all' : 'actual',
      'month_count': monthCount,
      'accounts': accounts,
      'current_month': {
        'income': displayIncome,
        'expense': displayExpense,
        'net': displayIncome - displayExpense,
        'actual_income': income,
        'actual_expense': expense,
        'actual_net': income - expense,
        'planned_income': plannedIncome,
        'planned_expense': plannedExpense,
      },
      'last_month': {
        'income': lastIncome,
        'expense': lastExpense,
      },
      'expense_categories': expenseCategories,
      'income_categories': incomeCategories,
      'budgets': budgets,
      'goals': goals,
      'recent_months': recentMonths,
    };
  }
}

class AiNetworkException implements Exception {
  final String message;
  final Exception? originalError;
  AiNetworkException(this.message, {this.originalError});
  @override
  String toString() => message;
}
