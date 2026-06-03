import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/finance_repository.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/month_key.dart';

class AiAnalysisService {
  final String gatewayUrl;

  AiAnalysisService({
    required this.gatewayUrl,
  });

  Future<String> generateAnalysis(FinanceRepository repository) async {
    final data = _buildRequestData(repository);
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

  Map<String, dynamic> _buildRequestData(FinanceRepository repository) {
    final now = DateTime.now();
    final currentMonth = monthKeyFromDate(now);
    final lastMonth = monthKeyFromDate(DateTime(now.year, now.month - 1));

    // Account summary
    final accounts = <Map<String, dynamic>>[];
    for (final group in ReportGroup.values) {
      for (final acc in repository.accountsByGroup(group)) {
        final balance = repository.accountBalanceAt(acc.id, now);
        accounts.add({
          'name': acc.name,
          'type': acc.accountType.name,
          'balance': balance,
        });
      }
    }

    // Monthly summary - 分开 actual 和 forecast
    final income = repository.totalIncomeForMonth(currentMonth);
    final expense = repository.totalExpenseForMonth(currentMonth);
    final lastIncome = repository.totalIncomeForMonth(lastMonth);
    final lastExpense = repository.totalExpenseForMonth(lastMonth);

    // 计算 actual only（排除 planned）
    double actualIncome = 0;
    double actualExpense = 0;
    double plannedIncome = 0;
    double plannedExpense = 0;

    for (final tx in repository.transactions) {
      final txMonth = monthKeyFromDate(tx.transactionDate);
      if (txMonth != currentMonth) continue;
      final isPlanned = tx.status == TransactionStatus.planned;
      if (tx.type == TransactionType.income) {
        if (isPlanned) {
          plannedIncome += tx.amount;
        } else {
          actualIncome += tx.amount;
        }
      } else if (tx.type == TransactionType.expense) {
        if (isPlanned) {
          plannedExpense += tx.amount;
        } else {
          actualExpense += tx.amount;
        }
      }
    }

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

    // 近6个月实际收支趋势（用于推演）
    final recentMonths = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i);
      final mKey = monthKeyFromDate(mDate);
      final mIncome = repository.totalIncomeForMonth(mKey);
      final mExpense = repository.totalExpenseForMonth(mKey);
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
      'accounts': accounts,
      'current_month': {
        'income': income,
        'expense': expense,
        'net': income - expense,
        'actual_income': actualIncome,
        'actual_expense': actualExpense,
        'actual_net': actualIncome - actualExpense,
        'planned_income': plannedIncome,
        'planned_expense': plannedExpense,
        'planned_net': plannedIncome - plannedExpense,
      },
      'last_month': {
        'income': lastIncome,
        'expense': lastExpense,
      },
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
