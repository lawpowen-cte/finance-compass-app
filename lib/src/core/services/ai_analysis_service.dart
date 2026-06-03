import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/finance_repository.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/month_key.dart';

class AiAnalysisService {
  final String baseUrl;
  final String apiKey;
  final String model;

  AiAnalysisService({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  Future<String> generateAnalysis(FinanceRepository repository) async {
    final prompt = _buildPrompt(repository);
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个个人财务分析师。根据用户的财务数据生成简洁的中文分析报告。输出纯HTML，不要markdown，不要```html```包裹。使用内联样式，配色柔和（背景#F6F8FA，文字#3D6058，绿色#7BAE8A，红色#D49A9A）。表格用border-collapse:collapse，td/th加padding:6px 10px。整体padding:16px。',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 16000,
        'temperature': 0.3,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('AI API error: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final message = data['choices'][0]['message'];
    final content = (message['content'] as String?)?.trim() ?? '';
    if (content.isEmpty) {
      // MiMo reasoning model may put response in reasoning_content
      final reasoning = (message['reasoning_content'] as String?)?.trim() ?? '';
      if (reasoning.isNotEmpty) {
        return '<div style="padding:16px"><p>$reasoning</p></div>';
      }
      throw Exception('AI 返回内容为空，请检查 API 配置或稍后重试');
    }
    return content;
  }

  String _buildPrompt(FinanceRepository repository) {
    final now = DateTime.now();
    final currentMonth = monthKeyFromDate(now);
    final lastMonth = monthKeyFromDate(DateTime(now.year, now.month - 1));

    // Account summary
    final accountLines = <String>[];
    for (final group in ReportGroup.values) {
      final accounts = repository.accountsByGroup(group);
      if (accounts.isEmpty) continue;
      for (final acc in accounts) {
        final balance = repository.accountBalanceAt(acc.id, now);
        accountLines.add('${acc.name} (${acc.accountType.name}): ${formatMoney(balance, currency: acc.currency)}');
      }
    }

    // Monthly summary
    final income = repository.totalIncomeForMonth(currentMonth);
    final expense = repository.totalExpenseForMonth(currentMonth);
    final lastIncome = repository.totalIncomeForMonth(lastMonth);
    final lastExpense = repository.totalExpenseForMonth(lastMonth);

    // Budget
    final budgetLines = <String>[];
    final budgets = repository.activeBudgetsForMonth(currentMonth);
    for (final b in budgets) {
      final effective = repository.effectiveBudgetForMonth(b, currentMonth);
      final spent = repository.expenseTotalForCategory(b.categoryId, currentMonth);
      final catName = repository.categoryName(b.categoryId);
      budgetLines.add('$catName: 预算${formatMoney(effective)} 已用${formatMoney(spent)}');
    }

    // Asset goals
    final goalLines = <String>[];
    final goalSummaries = repository.assetGoalSummaries();
    for (final g in goalSummaries) {
      final status = g.isReached ? '已达成' : '进行中';
      final progress = (g.progressRatio * 100).toStringAsFixed(1);
      final remaining = g.goal.targetAmount - g.currentAssets;
      goalLines.add('${g.goal.name}: 目标${formatMoney(g.goal.targetAmount)} 当前${formatMoney(g.currentAssets)} 进度$progress% $status${g.isReached ? "" : " 还差${formatMoney(remaining)}"}');
    }

    // Recent transactions
    final recent = repository.recentTransactions(limit: 10);
    final txLines = recent.map((t) {
      final sign = t.type == TransactionType.income ? '+' : '-';
      return '${monthKeyFromDate(t.transactionDate)} ${t.type.name} $sign${formatMoney(t.amount, currency: t.currency)}';
    }).toList();

    return '''
请分析以下财务数据并生成报告，包含：
1. 财务概览（总资产、本月收支、与上月对比）
2. 账户分析（各账户余额、资产配置建议）
3. 预算执行情况
4. 资产目标预测（根据历史数据推算预计达标时间）
5. 支出建议

【账户余额】
${accountLines.join('\n')}

【本月 ($currentMonth) 收支】
收入: ${formatMoney(income)}
支出: ${formatMoney(expense)}
净现金流: ${formatMoney(income - expense)}

【上月 ($lastMonth) 收支】
收入: ${formatMoney(lastIncome)}
支出: ${formatMoney(lastExpense)}

【预算执行】
${budgetLines.join('\n')}

【资产目标】
${goalLines.join('\n')}

【近期交易】
${txLines.join('\n')}
''';
  }
}
