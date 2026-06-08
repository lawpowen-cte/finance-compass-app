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
  static const defaultFutureMonthCount = 6;

  static const financeAnalysisSystemPrompt = '''
你是一位专业、谨慎、重视事实口径的个人财务分析师。请只根据用户提供的 Finance Compass JSON 给出简洁但有行动价值的分析。

输出要求：
- 使用简体中文。
- 输出纯文字，不要 HTML，不要代码块。
- 金额使用 JSON 的 base_currency 作为货币前缀，保留 2 位小数。
- 必须区分 actual（已发生）与 planned（预计/计划），不要把 planned 当作已经发生。
- 先用 JSON 已计算好的汇总字段和 cash_flow_projection，再引用交易明细解释原因。
- 未来推演优先使用 future_transactions、monthly_actual_planned、future_monthly_actual_planned、cash_flow_projection、budgets_by_month 和 recurring_transaction_rules；历史均值只能在未来数据缺失时补足，并明确标为估算。
- 如果 recurring_transaction_rules 已经生成了未来 planned 交易，不要重复计算；规则主要用于解释固定收支来源，或补足尚未生成的后续月份。
- 不要编造 JSON 中没有的数据；数据不足时明确写出假设和置信度。
- 避免泛泛而谈，每条建议都要指向具体月份、账户、类别或金额区间。

必须包含：
财务总结
- 本月 actual 与 planned 的分别和合计情况，同时说明本月已发生部分是否足够代表全月。
- 与上月对比的收入、支出、结余变化。
- 资产分布、现金/信用卡压力、预算执行亮点或风险。
- 用一句话判断整体财务健康度，并给出置信度。

未来推演
- 按 future_months 逐月说明预计收入、预计支出、预计结余、月末现金/信用压力。
- 先引用已记录的 future planned/recurring 数据，再用历史均值补空白月份。
- 标出未来 1-2 个最需要注意的月份、账户或类别。

建议
- 给出 3-5 条具体行动，优先关注现金流、预算、即将到来的大额支出、可减少的类别。
''';

  AiAnalysisService({
    required this.gatewayUrl,
  });

  final String gatewayUrl;

  Future<String> generateAnalysis(
    FinanceRepository repository, {
    bool includePlanned = false,
    int monthCount = 6,
    int futureMonthCount = defaultFutureMonthCount,
  }) async {
    final data = buildRequestData(
      repository,
      includePlanned: includePlanned,
      monthCount: monthCount,
      futureMonthCount: futureMonthCount,
    );
    final prompt = buildAnalysisPrompt(data);
    final uri = Uri.parse('$gatewayUrl/api/analyze');

    const maxRetries = 2;
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'data': data,
                'prompt': prompt,
              }),
            )
            .timeout(const Duration(seconds: 300));

        if (response.statusCode != 200) {
          throw Exception(
              'Gateway 返回 ${response.statusCode}: ${response.body}');
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

  static Map<String, dynamic> buildRequestData(
    FinanceRepository repository, {
    required bool includePlanned,
    required int monthCount,
    int futureMonthCount = defaultFutureMonthCount,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonth = monthKeyFromDate(now);
    final lastMonth = monthKeyFromDate(DateTime(now.year, now.month - 1));
    final daysInCurrentMonth = DateTime(now.year, now.month + 1, 0).day;
    final historyMonthKeys = recentMonthKeys(count: monthCount, anchor: now);
    final futureMonthKeys = List.generate(
      futureMonthCount,
      (index) => monthKeyFromDate(DateTime(now.year, now.month + index + 1)),
    );
    final analysisMonthKeys = [
      ...historyMonthKeys,
      ...futureMonthKeys,
    ];
    final cutoffDate = repository.currentMonthCutoffDate();

    final accounts = <Map<String, dynamic>>[];
    for (final group in ReportGroup.values) {
      for (final account in repository.accountsByGroup(group)) {
        final balance = repository.accountBalanceAtBase(account.id, cutoffDate);
        accounts.add({
          'name': account.name,
          'type': account.accountType.name,
          'report_group': account.reportGroup.name,
          'currency': account.currency,
          'balance': balance,
          'balance_base': balance,
          'native_balance': repository.accountBalanceAt(account.id, cutoffDate),
          'is_active': account.isActive,
        });
      }
    }

    final income = repository.totalIncomeForMonth(currentMonth);
    final expense = repository.totalExpenseForMonth(currentMonth);
    final plannedIncome = repository.plannedIncomeForMonth(currentMonth);
    final plannedExpense = repository.plannedExpenseForMonth(currentMonth);
    final displayIncome = includePlanned ? income + plannedIncome : income;
    final displayExpense = includePlanned ? expense + plannedExpense : expense;

    final lastActualIncome = repository.totalIncomeForMonth(lastMonth);
    final lastActualExpense = repository.totalExpenseForMonth(lastMonth);
    final lastPlannedIncome = repository.plannedIncomeForMonth(lastMonth);
    final lastPlannedExpense = repository.plannedExpenseForMonth(lastMonth);
    final lastIncome =
        lastActualIncome + (includePlanned ? lastPlannedIncome : 0);
    final lastExpense =
        lastActualExpense + (includePlanned ? lastPlannedExpense : 0);

    final monthRows = analysisMonthKeys
        .map(
          (monthKey) => _monthlyRow(
            repository,
            monthKey: monthKey,
            currentMonth: currentMonth,
            includePlanned: includePlanned,
          ),
        )
        .toList();
    final futureMonthRows = futureMonthKeys
        .map(
          (monthKey) => _monthlyRow(
            repository,
            monthKey: monthKey,
            currentMonth: currentMonth,
            includePlanned: true,
          ),
        )
        .toList();
    final recentMonthsForGateway = (includePlanned
            ? monthRows
            : monthRows.where((item) => item['period'] != 'future').toList())
        .map(
          (item) => {
            'month': item['month'],
            'income': item['analysis_income'],
            'expense': item['analysis_expense'],
            'net': item['analysis_net'],
            'period': item['period'],
            'actual_income': item['actual_income'],
            'actual_expense': item['actual_expense'],
            'planned_income': item['planned_income'],
            'planned_expense': item['planned_expense'],
          },
        )
        .where(
          (item) =>
              (item['income'] as double) != 0 ||
              (item['expense'] as double) != 0 ||
              item['period'] == 'future',
        )
        .toList();

    final categoryDivisor =
        monthCount + (includePlanned ? futureMonthCount : 0);
    final expenseCategories = _categorySummary(
      repository,
      type: CategoryType.expense,
      monthKeys: analysisMonthKeys,
      includePlanned: includePlanned,
      divisor: categoryDivisor,
    );
    final incomeCategories = _categorySummary(
      repository,
      type: CategoryType.income,
      monthKeys: analysisMonthKeys,
      includePlanned: includePlanned,
      divisor: categoryDivisor,
    );

    final budgetsByMonth = {
      for (final monthKey in [currentMonth, ...futureMonthKeys])
        monthKey: _budgetRowsForMonth(repository, monthKey),
    };
    final budgets = budgetsByMonth[currentMonth] ?? const [];

    final goals = <Map<String, dynamic>>[];
    for (final goal in repository.assetGoalSummaries()) {
      goals.add({
        'name': goal.goal.name,
        'target': goal.goal.targetAmount,
        'current': goal.currentAssets,
        'progress': (goal.progressRatio * 100).toStringAsFixed(1),
        'is_reached': goal.isReached,
      });
    }

    final futureTransactions = _transactionsInWindow(
      repository,
      startDateExclusive: today,
      endDateInclusive: DateTime(now.year, now.month + futureMonthCount + 1, 0),
      limit: 120,
    );
    final recentActualTransactions = _transactionsInWindow(
      repository,
      endDateInclusive: today,
      limit: 50,
      descending: true,
      actualOnly: true,
    );
    final recurringRules = repository.recurringTransactionRules
        .map(
          (rule) => _recurringRuleRow(
            repository,
            rule,
            now: now,
            futureMonthCount: futureMonthCount,
          ),
        )
        .toList();
    final cashFlowProjection = repository
        .futureCashFlowProjection(months: futureMonthCount + 1)
        .map(
          (item) => {
            'month': item.monthKey,
            'income': item.income,
            'expense': item.expense,
            'transfers': item.transfers,
            'net': item.net,
            'ending_cash_after_credit': item.endingCash,
          },
        )
        .toList();
    final futureMonthsWithKnownData = futureMonthRows
        .where((item) => _monthHasKnownFutureData(item))
        .map((item) => item['month'])
        .toList();
    final budgetRiskRows = _budgetRiskRows(budgetsByMonth);

    return {
      'schema_version': 3,
      'prompt_version': 'finance_compass_current_future_v2',
      'generated_at': DateTime.now().toIso8601String(),
      'base_currency': repository.baseCurrency,
      'analysis_contract': {
        'actual': 'completed or settled records that affect real balances',
        'planned':
            'user-entered estimates that should not be treated as completed cash flow',
        'analysis_income': includePlanned
            ? 'actual_income plus planned_income'
            : 'actual_income only',
        'analysis_expense': includePlanned
            ? 'actual_expense plus planned_expense'
            : 'actual_expense only',
        'cash_flow_projection':
            'cash and credit pressure projection; this is not total net worth',
        'recommended_source_order': [
          'current_month and last_month summaries',
          'cash_flow_projection',
          'future_monthly_actual_planned',
          'future_transactions',
          'budgets_by_month',
          'recurring_transaction_rules',
          'recent_actual_transactions',
        ],
      },
      'data_mode': includePlanned ? 'all' : 'actual',
      'data_mode_note': includePlanned
          ? 'analysis fields include actual plus planned records; actual/planned remain separated'
          : 'analysis fields use actual records only; future planned data is still included in dedicated future fields',
      'month_count': monthCount,
      'future_month_count': futureMonthCount,
      'current_month_key': currentMonth,
      'current_day_of_month': today.day,
      'days_in_current_month': daysInCurrentMonth,
      'current_month_elapsed_ratio':
          double.parse((today.day / daysInCurrentMonth).toStringAsFixed(2)),
      'history_months': historyMonthKeys,
      'future_months': futureMonthKeys,
      'analysis_months': analysisMonthKeys,
      'currency_priority': repository.currencyPriority,
      'exchange_rates_to_base': repository.exchangeRatesToBase,
      'accounts': accounts,
      'assets_by_group': {
        'cash': repository.totalAssetsByGroup(ReportGroup.cash),
        'credit': repository.totalAssetsByGroup(ReportGroup.credit),
        'investment': repository.totalAssetsByGroup(ReportGroup.investment),
        'retirement': repository.totalAssetsByGroup(ReportGroup.retirement),
      },
      'total_assets': repository.totalAssets(),
      'current_month': {
        'income': displayIncome,
        'expense': displayExpense,
        'net': displayIncome - displayExpense,
        'actual_income': income,
        'actual_expense': expense,
        'actual_net': income - expense,
        'planned_income': plannedIncome,
        'planned_expense': plannedExpense,
        'planned_net': plannedIncome - plannedExpense,
      },
      'last_month': {
        'income': lastIncome,
        'expense': lastExpense,
        'net': lastIncome - lastExpense,
        'actual_income': lastActualIncome,
        'actual_expense': lastActualExpense,
        'planned_income': lastPlannedIncome,
        'planned_expense': lastPlannedExpense,
      },
      'monthly_actual_planned': monthRows,
      'future_monthly_actual_planned': futureMonthRows,
      'expense_categories': expenseCategories,
      'income_categories': incomeCategories,
      'budgets': budgets,
      'budgets_by_month': budgetsByMonth,
      'goals': goals,
      'cash_flow_projection': cashFlowProjection,
      'future_transactions': futureTransactions,
      'recent_actual_transactions': recentActualTransactions,
      'recurring_transaction_rules': recurringRules,
      'budget_risks': budgetRiskRows,
      'data_quality': {
        'future_months_requested': futureMonthCount,
        'future_months_with_known_planned_data':
            futureMonthsWithKnownData.length,
        'future_months_missing_known_planned_data':
            futureMonthCount - futureMonthsWithKnownData.length,
        'future_months_with_known_planned_data_keys': futureMonthsWithKnownData,
        'future_transactions_count': futureTransactions.length,
        'recurring_rules_count': recurringRules.length,
        'recent_actual_transactions_count': recentActualTransactions.length,
        'budget_risk_count': budgetRiskRows.length,
      },
      'recent_months': recentMonthsForGateway,
      'analysis_notes': [
        'planned transactions are user-entered estimates, not completed cash flow',
        'future_transactions may already include generated recurring records',
        'recurring_transaction_rules explain fixed patterns and should not be double-counted when matching future planned transactions exist',
        'cash_flow_projection focuses on cash and credit groups, while total_assets includes investment and retirement groups',
      ],
    };
  }

  static String buildAnalysisPrompt(Map<String, dynamic> data) {
    final baseCurrency = data['base_currency'] ?? 'MYR';
    final futureMonthCount =
        data['future_month_count'] ?? defaultFutureMonthCount;
    return '''
$financeAnalysisSystemPrompt

请分析下面的 Finance Compass JSON。重点是解释当前财务状态和未来 $futureMonthCount 个月可能情况。

请特别注意：
1. base_currency 是 $baseCurrency，所有 *_base 或汇总金额都已折算到该货币。
2. analysis_contract 是本次分析口径，必须优先遵守。
3. monthly_actual_planned 同时包含历史、当前、未来月份；period=future 的月份通常主要来自 planned 记录。
4. future_transactions 是用户已经提前记录的未来交易，其中 recurring_rule_id 不为空的记录通常来自周期交易规则。
5. recurring_transaction_rules 是固定收入/支出/转账规则；如果对应月份已经有 future_transactions，请用交易金额，不要重复加一次规则金额。
6. budgets_by_month 反映当前月和未来月预算，remaining_after_committed 可以用于判断预算压力。
7. cash_flow_projection 是基于现金和信用账户的未来现金流压力，不等同于总资产。
8. data_quality 描述未来计划数据覆盖度；覆盖不足时，请降低推演置信度并说明假设。

请按这个顺序输出：
财务总结
未来 $futureMonthCount 个月推演
建议
''';
  }

  static String buildExternalAnalysisText(
    FinanceRepository repository, {
    int monthCount = 6,
    int futureMonthCount = defaultFutureMonthCount,
  }) {
    final data = buildRequestData(
      repository,
      includePlanned: true,
      monthCount: monthCount,
      futureMonthCount: futureMonthCount,
    );
    final prompt = buildAnalysisPrompt(data);
    final jsonText = const JsonEncoder.withIndent('  ').convert(data);
    return '''
$prompt

【财务数据 JSON】
---BEGIN_FINANCE_COMPASS_JSON---
$jsonText
---END_FINANCE_COMPASS_JSON---

请直接根据上面的 JSON 分析；如果你无法读取附件或外部文件，请优先使用这段内嵌 JSON。
''';
  }

  static Map<String, dynamic> _monthlyRow(
    FinanceRepository repository, {
    required String monthKey,
    required String currentMonth,
    required bool includePlanned,
  }) {
    final actualIncome = repository.totalIncomeForMonth(monthKey);
    final actualExpense = repository.totalExpenseForMonth(monthKey);
    final plannedIncome = repository.plannedIncomeForMonth(monthKey);
    final plannedExpense = repository.plannedExpenseForMonth(monthKey);
    final analysisIncome = actualIncome + (includePlanned ? plannedIncome : 0);
    final analysisExpense =
        actualExpense + (includePlanned ? plannedExpense : 0);
    return {
      'month': monthKey,
      'period': monthKey.compareTo(currentMonth) < 0
          ? 'past'
          : monthKey == currentMonth
              ? 'current'
              : 'future',
      'actual_income': actualIncome,
      'actual_expense': actualExpense,
      'actual_net': actualIncome - actualExpense,
      'planned_income': plannedIncome,
      'planned_expense': plannedExpense,
      'planned_net': plannedIncome - plannedExpense,
      'total_known_income': actualIncome + plannedIncome,
      'total_known_expense': actualExpense + plannedExpense,
      'total_known_net':
          actualIncome + plannedIncome - actualExpense - plannedExpense,
      'analysis_income': analysisIncome,
      'analysis_expense': analysisExpense,
      'analysis_net': analysisIncome - analysisExpense,
    };
  }

  static bool _monthHasKnownFutureData(Map<String, dynamic> row) {
    return (row['planned_income'] as double) != 0 ||
        (row['planned_expense'] as double) != 0 ||
        (row['actual_income'] as double) != 0 ||
        (row['actual_expense'] as double) != 0;
  }

  static List<Map<String, dynamic>> _budgetRiskRows(
    Map<String, List<Map<String, dynamic>>> budgetsByMonth,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final entry in budgetsByMonth.entries) {
      for (final budget in entry.value) {
        final remaining =
            (budget['remaining_after_committed'] as num).toDouble();
        if (remaining >= 0) {
          continue;
        }
        rows.add({
          'month': entry.key,
          'category': budget['category'],
          'budget': (budget['budget'] as num).toDouble(),
          'committed_spend': (budget['committed_spend'] as num).toDouble(),
          'over_budget_by': -remaining,
        });
      }
    }
    rows.sort(
      (a, b) => (b['over_budget_by'] as double)
          .compareTo(a['over_budget_by'] as double),
    );
    return rows.take(12).toList();
  }

  static List<Map<String, dynamic>> _categorySummary(
    FinanceRepository repository, {
    required CategoryType type,
    required List<String> monthKeys,
    required bool includePlanned,
    required int divisor,
  }) {
    final actual = _categoryTotals(
      repository,
      type: type,
      monthKeys: monthKeys,
      includePlanned: false,
    );
    final planned = _categoryTotals(
      repository,
      type: type,
      monthKeys: monthKeys,
      plannedOnly: true,
    );
    final categoryIds = <String>{...actual.keys, ...planned.keys};
    final rows = <Map<String, dynamic>>[];
    for (final categoryId in categoryIds) {
      final actualTotal = actual[categoryId] ?? 0;
      final plannedTotal = planned[categoryId] ?? 0;
      final total = actualTotal + (includePlanned ? plannedTotal : 0);
      if (total == 0 && plannedTotal == 0 && actualTotal == 0) {
        continue;
      }
      rows.add({
        'name': _categoryName(repository, categoryId),
        'total': total,
        'actual_total': actualTotal,
        'planned_total': plannedTotal,
        'monthly_avg': divisor <= 0 ? total : total / divisor,
      });
    }
    rows.sort(
      (a, b) => (b['total'] as double).compareTo(a['total'] as double),
    );
    return rows;
  }

  static Map<String, double> _categoryTotals(
    FinanceRepository repository, {
    required CategoryType type,
    required List<String> monthKeys,
    bool includePlanned = true,
    bool plannedOnly = false,
  }) {
    final allowedIds = repository.categories
        .where((category) => category.type == type)
        .map((category) => category.id)
        .toSet();
    final totals = <String, double>{};
    for (final transaction in repository.transactions) {
      final categoryId = transaction.categoryId;
      if (categoryId == null || !allowedIds.contains(categoryId)) {
        continue;
      }
      if (!monthKeys.contains(monthKeyFromDate(transaction.transactionDate))) {
        continue;
      }
      if (plannedOnly && transaction.status != TransactionStatus.planned) {
        continue;
      }
      if (!includePlanned && transaction.status == TransactionStatus.planned) {
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
      totals[categoryId] = (totals[categoryId] ?? 0) +
          repository.transactionAmountInBase(transaction);
    }
    return totals;
  }

  static List<Map<String, dynamic>> _budgetRowsForMonth(
    FinanceRepository repository,
    String monthKey,
  ) {
    return repository.activeBudgetsForMonth(monthKey).map((budget) {
      final effective = repository.effectiveBudgetForMonth(budget, monthKey);
      final actualSpent =
          repository.expenseTotalForCategory(budget.categoryId, monthKey);
      final plannedSpent = repository.plannedExpenseTotalForCategory(
        budget.categoryId,
        monthKey,
      );
      final committed = actualSpent + plannedSpent;
      return {
        'category': _categoryName(repository, budget.categoryId),
        'budget': effective,
        'spent': actualSpent,
        'actual_spent': actualSpent,
        'planned_spent': plannedSpent,
        'committed_spend': committed,
        'remaining_after_actual': effective - actualSpent,
        'remaining_after_committed': effective - committed,
        'rollover_enabled': budget.rolloverEnabled,
        'alert_threshold': budget.alertThreshold,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> _transactionsInWindow(
    FinanceRepository repository, {
    DateTime? startDateExclusive,
    required DateTime endDateInclusive,
    int limit = 80,
    bool descending = false,
    bool actualOnly = false,
  }) {
    final items = repository.transactions.where((transaction) {
      if (actualOnly && transaction.status == TransactionStatus.planned) {
        return false;
      }
      if (startDateExclusive != null &&
          !transaction.transactionDate.isAfter(startDateExclusive)) {
        return false;
      }
      if (transaction.transactionDate.isAfter(endDateInclusive)) {
        return false;
      }
      return true;
    }).toList()
      ..sort(
        (a, b) => descending
            ? b.transactionDate.compareTo(a.transactionDate)
            : a.transactionDate.compareTo(b.transactionDate),
      );
    return items
        .take(limit)
        .map((item) => _transactionRow(repository, item))
        .toList();
  }

  static Map<String, dynamic> _transactionRow(
    FinanceRepository repository,
    FinanceTransaction transaction,
  ) {
    return {
      'date': _dateText(transaction.transactionDate),
      'month': monthKeyFromDate(transaction.transactionDate),
      'type': transaction.type.name,
      'status': transaction.status.name,
      'is_planned': transaction.status == TransactionStatus.planned,
      'is_recurring_instance': transaction.recurringRuleId != null,
      'recurring_rule_id': transaction.recurringRuleId,
      'account': _accountName(repository, transaction.accountId),
      'to_account': transaction.toAccountId == null
          ? null
          : _accountName(repository, transaction.toAccountId!),
      'category': _categoryName(repository, transaction.categoryId),
      'amount': transaction.amount,
      'currency': transaction.currency,
      'amount_base': repository.transactionAmountInBase(transaction),
      'to_amount': transaction.toAmount,
      'to_currency': transaction.toCurrency,
      'description': transaction.description,
      'merchant': transaction.merchant,
    };
  }

  static Map<String, dynamic> _recurringRuleRow(
    FinanceRepository repository,
    RecurringTransactionRule rule, {
    required DateTime now,
    required int futureMonthCount,
  }) {
    return {
      'id': rule.id,
      'name': rule.name,
      'type': rule.type.name,
      'status_when_generated': rule.status.name,
      'is_active': rule.isActive,
      'account': _accountName(repository, rule.accountId),
      'to_account': rule.toAccountId == null
          ? null
          : _accountName(repository, rule.toAccountId!),
      'category': _categoryName(repository, rule.categoryId),
      'amount': rule.amount,
      'currency': rule.currency,
      'amount_base': repository.convertToBase(rule.amount, rule.currency),
      'to_amount': rule.toAmount,
      'to_currency': rule.toCurrency,
      'interval_months': rule.intervalMonths,
      'start_date': _dateText(rule.startDate),
      'end_date': rule.endDate == null ? null : _dateText(rule.endDate!),
      'generated_month_keys': rule.generatedMonthKeys,
      'next_occurrences': _nextRecurringOccurrences(
        rule,
        now: now,
        futureMonthCount: futureMonthCount,
      ),
    };
  }

  static List<Map<String, dynamic>> _nextRecurringOccurrences(
    RecurringTransactionRule rule, {
    required DateTime now,
    required int futureMonthCount,
  }) {
    if (!rule.isActive) {
      return const [];
    }
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(now.year, now.month + futureMonthCount + 1, 0);
    final rows = <Map<String, dynamic>>[];
    var cursor = DateTime(
      rule.startDate.year,
      rule.startDate.month,
      rule.startDate.day,
    );
    var guard = 0;
    while (!cursor.isAfter(endDate) && guard++ < 240) {
      if (cursor.isAfter(today) &&
          (rule.endDate == null || !cursor.isAfter(rule.endDate!))) {
        final occurrenceMonthKey = monthKeyFromDate(cursor);
        rows.add({
          'date': _dateText(cursor),
          'month': occurrenceMonthKey,
          'already_generated_as_transaction':
              rule.generatedMonthKeys.contains(occurrenceMonthKey),
        });
      }
      cursor = DateTime(
        cursor.year,
        cursor.month + rule.intervalMonths,
        cursor.day,
      );
    }
    return rows;
  }

  static String _categoryName(
      FinanceRepository repository, String? categoryId) {
    if (categoryId == null) {
      return '未分类';
    }
    for (final category in repository.categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return '未命名类别';
  }

  static String _accountName(FinanceRepository repository, String accountId) {
    for (final account in repository.accounts) {
      if (account.id == accountId) {
        return account.name;
      }
    }
    return '未知账户';
  }

  static String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class AiNetworkException implements Exception {
  final String message;
  final Exception? originalError;
  AiNetworkException(this.message, {this.originalError});
  @override
  String toString() => message;
}
