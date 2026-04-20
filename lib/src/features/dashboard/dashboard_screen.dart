import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/forecast_summary.dart';
import '../../core/models/monthly_summary.dart';
import '../../core/models/transaction.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? selectedYear = DateTime.now().year;
  int? selectedMonth;
  String? selectedBudgetMonth;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final transactions = [...repository.transactions]
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    final now = DateTime.now();
    final latestTransactionDate = transactions.isEmpty ? now : transactions.last.transactionDate;
    final latestMonthDate = DateTime(latestTransactionDate.year, latestTransactionDate.month);

    final years = transactions.map((item) => item.transactionDate.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final availableMonthsForYear = selectedYear == null
        ? <int>[]
        : transactions
            .where((item) => item.transactionDate.year == selectedYear)
            .map((item) => item.transactionDate.month)
            .toSet()
            .toList()
          ..sort();

    if (selectedYear == null && selectedMonth != null) {
      selectedMonth = null;
    }
    if (selectedYear != null &&
        selectedMonth != null &&
        !availableMonthsForYear.contains(selectedMonth)) {
      selectedMonth = null;
    }

    final periodAnchorMonth = _resolveAnchorMonth(latestMonthDate);
    final periodStart = _resolvePeriodStart(periodAnchorMonth);
    final periodEnd = _resolvePeriodEnd(periodAnchorMonth);
    final assetEnd = DateTime(
      periodAnchorMonth.year,
      periodAnchorMonth.month + 2,
      0,
      23,
      59,
      59,
    );
    final settlementEnd = DateTime(
      periodAnchorMonth.year,
      periodAnchorMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    final periodTransactions = transactions.where((transaction) {
      return !transaction.transactionDate.isBefore(periodStart) &&
          !transaction.transactionDate.isAfter(periodEnd);
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final periodMonthKeys = _monthKeysBetween(periodStart, periodEnd)
        .where((monthKey) {
          return repository.totalIncomeForMonth(monthKey) != 0 ||
              repository.totalExpenseForMonth(monthKey) != 0;
        })
        .toList();

    final monthlySummaries = periodMonthKeys
        .map(
          (monthKey) => MonthlySummary(
            monthKey: monthKey,
            income: repository.totalIncomeForMonth(monthKey),
            expense: repository.totalExpenseForMonth(monthKey),
          ),
        )
        .toList();

    final income = periodTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = periodTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final cashTotal = _balanceForGroup(repository, ReportGroup.cash, assetEnd);
    final creditTotal = -_balanceForGroup(repository, ReportGroup.credit, assetEnd);
    final investmentTotal = _balanceForGroup(repository, ReportGroup.investment, assetEnd);
    final retirementTotal = _balanceForGroup(repository, ReportGroup.retirement, assetEnd);

    final settlementCash = _balanceForGroup(repository, ReportGroup.cash, settlementEnd);
    final settlementCredit = _balanceForGroup(repository, ReportGroup.credit, settlementEnd);
    final settlementInvestment = _balanceForGroup(repository, ReportGroup.investment, settlementEnd);
    final settlementRetirement = _balanceForGroup(repository, ReportGroup.retirement, settlementEnd);
    final totalAssets =
        settlementCash + settlementInvestment + settlementRetirement + settlementCredit;
    final netAssets = settlementCash + settlementInvestment + settlementRetirement;

    final budgetMonthKeys = repository.budgetMonthKeys();
    final defaultBudgetMonth = budgetMonthKeys.contains(monthKeyFromDate(periodAnchorMonth))
        ? monthKeyFromDate(periodAnchorMonth)
        : (budgetMonthKeys.isEmpty ? monthKeyFromDate(now) : budgetMonthKeys.first);
    final activeBudgetMonth = budgetMonthKeys.contains(selectedBudgetMonth)
        ? selectedBudgetMonth!
        : defaultBudgetMonth;

    final activeBudgets = repository.activeBudgetsForMonth(activeBudgetMonth);
    final totalBudget = repository.totalEffectiveBudgetForMonth(activeBudgetMonth);
    final totalBudgetExpense = repository.totalBudgetExpenseForMonth(activeBudgetMonth);

    final showPlanningSections = selectedYear == null ||
        (selectedYear == now.year && (selectedMonth == null || selectedMonth == now.month));
    final futureExpenseReserve = repository.totalFutureExpense(monthsAhead: 3);
    final futureMonthlySummaries = repository.futureExpenseSummaries(months: 3);
    final upcomingExpenses = repository.upcomingExpenseTransactions();
    final forecast = _forecastFromSummaries(monthlySummaries, repository);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenHeader(title: '总览'),
        const SizedBox(height: 12),
        SectionCard(
          title: '时间范围',
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(
                    labelText: '年份',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...years.map(
                      (year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text('$year'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    selectedYear = value;
                    if (value == null) {
                      selectedMonth = null;
                    }
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: '月份',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...availableMonthsForYear.map(
                      (month) => DropdownMenuItem<int?>(
                        value: month,
                        child: Text(month.toString().padLeft(2, '0')),
                      ),
                    ),
                  ],
                  onChanged: selectedYear == null
                      ? null
                      : (value) => setState(() => selectedMonth = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _MetricCard(label: '现金余额(含下月)', amount: cashTotal),
            _MetricCard(label: '信用余额(含下月)', amount: creditTotal, tone: MetricTone.negative),
            _MetricCard(label: '投资余额(含下月)', amount: investmentTotal),
            _MetricCard(label: '退休余额(含下月)', amount: retirementTotal),
            _MetricCard(label: '期间收入', amount: income, tone: MetricTone.positive),
            _MetricCard(label: '期间支出', amount: expense, tone: MetricTone.negative),
            _MetricCard(label: '期间结余', amount: income - expense),
            _MetricCard(label: '累计资产(到当月)', amount: totalAssets),
            _MetricCard(label: '累计净资产(到当月)', amount: netAssets),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '月度对比',
          child: _MonthlyMatrix(summaries: monthlySummaries),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '预算监控',
          subtitle: '默认显示当前筛选范围对应月份，可切换查看',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: activeBudgetMonth,
                decoration: const InputDecoration(
                  labelText: '统计月份',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: budgetMonthKeys
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(monthLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => selectedBudgetMonth = value);
                },
              ),
              const SizedBox(height: 12),
              Text('总支出 / 总预算: ${formatMoney(totalBudgetExpense)} / ${formatMoney(totalBudget)}'),
              const SizedBox(height: 12),
              if (activeBudgets.isEmpty)
                Text(
                  '该月份还没有预算规则。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...activeBudgets.map((budget) {
                final effectiveBudget = repository.effectiveBudgetForMonth(budget, activeBudgetMonth);
                final spent = repository.expenseTotalForCategory(budget.categoryId, activeBudgetMonth);
                final ratio = effectiveBudget == 0 ? 0.0 : spent / effectiveBudget;
                final color = ratio > 1
                    ? const Color(0xFFB91C1C)
                    : ratio >= budget.alertThreshold
                        ? const Color(0xFFEA580C)
                        : const Color(0xFF15803D);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repository.categoryName(budget.categoryId),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: ratio.clamp(0, 1),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMoney(spent)} / ${formatMoney(effectiveBudget)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        if (showPlanningSections) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: '储蓄预测',
            child: _ForecastView(forecast: forecast),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '未来支出',
            child: _MonthlyMatrix(
              summaries: futureMonthlySummaries,
              firstLabel: '收入',
              secondLabel: '支出',
              thirdLabel: '结余',
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '未来 3 个月预留',
            child: Text(formatMoney(futureExpenseReserve)),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          title: '最近交易',
          child: Column(
            children: periodTransactions.take(6).map((transaction) {
              final isExpense = transaction.type == TransactionType.expense;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardColor.withValues(alpha: 0.86),
                  border: Border.all(color: Theme.of(context).cardColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(transaction.description ?? transaction.merchant ?? _typeLabel(transaction.type)),
                          const SizedBox(height: 4),
                          Text(
                            repository.accountName(transaction.accountId),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isExpense ? '-' : '+'}${formatMoney(transaction.amount, currency: transaction.currency)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isExpense ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (showPlanningSections) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: '未来支出条目',
            child: Column(
              children: upcomingExpenses.isEmpty
                  ? [
                      Text(
                        '暂无未来支出记录',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ]
                  : upcomingExpenses.map((transaction) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).cardColor.withValues(alpha: 0.86),
                          border: Border.all(color: Theme.of(context).cardColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(transaction.description ?? transaction.merchant ?? _typeLabel(transaction.type)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${repository.accountName(transaction.accountId)} · '
                                    '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-${formatMoney(transaction.amount, currency: transaction.currency)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  DateTime _resolveAnchorMonth(DateTime latestMonthDate) {
    if (selectedYear == null) {
      return latestMonthDate;
    }
    if (selectedMonth == null) {
      return DateTime(selectedYear!, 12);
    }
    return DateTime(selectedYear!, selectedMonth!);
  }

  DateTime _resolvePeriodStart(DateTime anchorMonth) {
    if (selectedYear == null) {
      final earliest = widget.repository.transactions.isEmpty
          ? DateTime.now()
          : widget.repository.transactions
              .map((item) => item.transactionDate)
              .reduce((left, right) => left.isBefore(right) ? left : right);
      return DateTime(earliest.year, earliest.month, 1);
    }
    if (selectedMonth == null) {
      return DateTime(selectedYear!, 1, 1);
    }
    return DateTime(anchorMonth.year, anchorMonth.month, 1);
  }

  DateTime _resolvePeriodEnd(DateTime anchorMonth) {
    return DateTime(anchorMonth.year, anchorMonth.month + 1, 0, 23, 59, 59);
  }

  List<String> _monthKeysBetween(DateTime start, DateTime end) {
    final monthKeys = <String>[];
    var cursor = DateTime(start.year, start.month);
    final limit = DateTime(end.year, end.month);
    while (!cursor.isAfter(limit)) {
      monthKeys.add(monthKeyFromDate(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return monthKeys;
  }

  double _balanceForGroup(FinanceRepository repository, ReportGroup group, DateTime endDate) {
    return repository.accounts
        .where((account) => account.reportGroup == group)
        .fold<double>(0, (sum, account) => sum + _balanceForAccount(repository, account, endDate));
  }

  double _balanceForAccount(FinanceRepository repository, Account account, DateTime endDate) {
    if (account.reportGroup == ReportGroup.investment ||
        account.reportGroup == ReportGroup.retirement) {
      final snapshots = repository.snapshotsForAccount(account.id);
      final eligibleSnapshots = snapshots.where(
        (snapshot) => !snapshot.snapshotDate.isAfter(endDate),
      );
      if (eligibleSnapshots.isNotEmpty) {
        return eligibleSnapshots.last.marketValue;
      }
    }
    return _rewindFromCurrentBalance(repository, account, endDate);
  }

  double _rewindFromCurrentBalance(
    FinanceRepository repository,
    Account account,
    DateTime endDate,
  ) {
    var balance = account.currentBalance;
    for (final transaction in repository.transactions) {
      if (!transaction.transactionDate.isAfter(endDate)) {
        continue;
      }

      if (transaction.accountId == account.id) {
        switch (transaction.type) {
          case TransactionType.income:
          case TransactionType.adjustment:
            balance -= transaction.amount;
          case TransactionType.expense:
            balance += transaction.amount;
          case TransactionType.transfer:
            balance += transaction.amount;
        }
      }

      if (transaction.toAccountId == account.id) {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  ForecastSummary _forecastFromSummaries(
    List<MonthlySummary> summaries,
    FinanceRepository repository,
  ) {
    final activeSummaries = summaries.where((item) => item.income != 0 || item.expense != 0).toList();
    if (activeSummaries.isEmpty) {
      return const ForecastSummary(
        averageMonthlyIncome: 0,
        averageMonthlyExpense: 0,
        averageMonthlySavings: 0,
        projectedSavingsInThreeMonths: 0,
        projectedSavingsInSixMonths: 0,
      );
    }

    final averageIncome =
        activeSummaries.fold<double>(0, (sum, item) => sum + item.income) / activeSummaries.length;
    final averageExpense =
        activeSummaries.fold<double>(0, (sum, item) => sum + item.expense) / activeSummaries.length;
    final averageSavings = averageIncome - averageExpense;
    final currentBase = repository.totalAssetsByGroup(ReportGroup.cash) +
        repository.totalAssetsByGroup(ReportGroup.investment) +
        repository.totalAssetsByGroup(ReportGroup.retirement) +
        repository.totalAssetsByGroup(ReportGroup.credit);

    return ForecastSummary(
      averageMonthlyIncome: averageIncome,
      averageMonthlyExpense: averageExpense,
      averageMonthlySavings: averageSavings,
      projectedSavingsInThreeMonths: currentBase + (averageSavings * 3),
      projectedSavingsInSixMonths: currentBase + (averageSavings * 6),
    );
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
      case TransactionType.transfer:
        return '转账';
      case TransactionType.adjustment:
        return '注资调整';
    }
  }
}

enum MetricTone { neutral, positive, negative }

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    this.tone = MetricTone.neutral,
  });

  final String label;
  final double amount;
  final MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      MetricTone.positive => const Color(0xFF15803D),
      MetricTone.negative => const Color(0xFFB91C1C),
      MetricTone.neutral => theme.textTheme.titleLarge?.color ?? Colors.black,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.cardColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              Text(currencyLabel('MYR'), style: theme.textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoneyValue(amount),
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyMatrix extends StatelessWidget {
  const _MonthlyMatrix({
    required this.summaries,
    this.firstLabel = '收入',
    this.secondLabel = '支出',
    this.thirdLabel = '结余',
  });

  final List<MonthlySummary> summaries;
  final String firstLabel;
  final String secondLabel;
  final String thirdLabel;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Text('暂无数据');
    }

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 52),
            ...summaries.map(
              (summary) => Expanded(
                child: Text(
                  monthLabel(summary.monthKey),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MatrixRow(label: firstLabel, values: summaries.map((item) => formatMoney(item.income)).toList()),
        _MatrixRow(label: secondLabel, values: summaries.map((item) => formatMoney(item.expense)).toList()),
        _MatrixRow(label: thirdLabel, values: summaries.map((item) => formatMoney(item.net)).toList()),
      ],
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(label)),
          ...values.map(
            (value) => Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastView extends StatelessWidget {
  const _ForecastView({required this.forecast});

  final ForecastSummary forecast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('平均收入: ${formatMoney(forecast.averageMonthlyIncome)}'),
        const SizedBox(height: 6),
        Text('平均支出: ${formatMoney(forecast.averageMonthlyExpense)}'),
        const SizedBox(height: 6),
        Text('月均结余: ${formatMoney(forecast.averageMonthlySavings)}'),
        const SizedBox(height: 10),
        Text('3 个月后预计储蓄: ${formatMoney(forecast.projectedSavingsInThreeMonths)}'),
        const SizedBox(height: 6),
        Text('6 个月后预计储蓄: ${formatMoney(forecast.projectedSavingsInSixMonths)}'),
      ],
    );
  }
}
