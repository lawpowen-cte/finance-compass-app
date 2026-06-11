import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/budget.dart';
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
  int? selectedMonth = DateTime.now().month;
  String? selectedBudgetMonth;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final transactions = [...repository.transactions]
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    final years = {
      now.year,
      previousMonth.year,
      ...transactions.map((item) => item.transactionDate.year),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    final availableMonthsForYear = selectedYear == null
        ? <int>[]
        : List.generate(12, (index) => index + 1);

    if (selectedYear == null && selectedMonth != null) {
      selectedMonth = null;
    }
    if (selectedYear != null &&
        selectedMonth != null &&
        !availableMonthsForYear.contains(selectedMonth)) {
      selectedMonth = null;
    }

    final periodAnchorMonth = _resolveAnchorMonth();
    final periodStart = _resolvePeriodStart(periodAnchorMonth);
    final periodEnd = _resolvePeriodEnd(periodAnchorMonth);
    final comparisonStart = DateTime(
      periodAnchorMonth.year,
      periodAnchorMonth.month - 2,
      1,
    );
    final assetEnd = DateTime(
      periodAnchorMonth.year,
      periodAnchorMonth.month + 1,
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

    final periodMonthKeys = _monthKeysBetween(comparisonStart, periodEnd).where(
      (monthKey) {
        return repository.totalIncomeForMonth(monthKey) != 0 ||
            repository.totalExpenseForMonth(monthKey) != 0;
      },
    ).toList();

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
        .where(
          (item) =>
              item.type == TransactionType.income &&
              item.status != TransactionStatus.planned,
        )
        .fold<double>(
          0,
          (sum, item) => sum + repository.transactionAmountInBase(item),
        );
    final expense = periodTransactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.status != TransactionStatus.planned,
        )
        .fold<double>(
          0,
          (sum, item) => sum + repository.transactionAmountInBase(item),
        );

    final cashTotal = _balanceForGroup(repository, ReportGroup.cash, assetEnd);
    final creditTotal = -_balanceForGroup(
      repository,
      ReportGroup.credit,
      assetEnd,
    );
    final investmentTotal = _balanceForGroup(
      repository,
      ReportGroup.investment,
      assetEnd,
    );
    final retirementTotal = _balanceForGroup(
      repository,
      ReportGroup.retirement,
      assetEnd,
    );

    final settlementCash = _balanceForGroup(
      repository,
      ReportGroup.cash,
      settlementEnd,
    );
    final settlementInvestment = _balanceForGroup(
      repository,
      ReportGroup.investment,
      settlementEnd,
    );
    final settlementRetirement = _balanceForGroup(
      repository,
      ReportGroup.retirement,
      settlementEnd,
    );
    final totalAssets =
        settlementCash + settlementInvestment + settlementRetirement;

    final budgetMonthKeys = repository.budgetMonthKeys();
    final fallbackBudgetMonth = monthKeyFromDate(now);
    final selectedFilterBudgetMonth =
        selectedYear != null && selectedMonth != null
            ? monthKeyFromDate(DateTime(selectedYear!, selectedMonth!))
            : fallbackBudgetMonth;
    final defaultBudgetMonth =
        budgetMonthKeys.contains(selectedFilterBudgetMonth)
            ? selectedFilterBudgetMonth
            : budgetMonthKeys.contains(fallbackBudgetMonth)
                ? fallbackBudgetMonth
                : (budgetMonthKeys.isEmpty
                    ? monthKeyFromDate(now)
                    : budgetMonthKeys.first);
    final activeBudgetMonth = budgetMonthKeys.contains(selectedBudgetMonth)
        ? selectedBudgetMonth!
        : defaultBudgetMonth;

    final activeBudgets = repository.activeBudgetsForMonth(activeBudgetMonth);
    final totalBudget = repository.totalEffectiveBudgetForMonth(
      activeBudgetMonth,
    );
    final totalBudgetExpense = repository.totalBudgetExpenseForMonth(
      activeBudgetMonth,
    );
    final sortedActiveBudgets = [...activeBudgets]..sort((left, right) {
        final leftRisk = _budgetUsageRatio(repository, left, activeBudgetMonth);
        final rightRisk = _budgetUsageRatio(
          repository,
          right,
          activeBudgetMonth,
        );
        return rightRisk.compareTo(leftRisk);
      });

    final showPlanningSections = selectedYear == null ||
        (selectedYear == now.year &&
            (selectedMonth == null || selectedMonth == now.month));
    final futureExpenseReserve = repository.totalFutureExpense(monthsAhead: 3);
    final futureMonthlySummaries = repository.futureExpenseSummaries(months: 3);
    final upcomingExpenses = repository.upcomingExpenseTransactions();
    final forecast = _forecastFromSummaries(monthlySummaries, repository);
    final cashFlowProjection = repository.futureCashFlowProjection(months: 6);
    final creditReminders = repository.creditCardPaymentReminders();
    final activeQuickRange = _activeQuickRangeLabel(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenHeader(title: '总览'),
        const SizedBox(height: 12),
        _DashboardRangeSelector(
          activeQuickRange: activeQuickRange,
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
          years: years,
          months: availableMonthsForYear,
          onCurrentMonth: () => setState(() {
            selectedYear = now.year;
            selectedMonth = now.month;
            selectedBudgetMonth = null;
          }),
          onPreviousMonth: () => setState(() {
            selectedYear = previousMonth.year;
            selectedMonth = previousMonth.month;
            selectedBudgetMonth = null;
          }),
          onCurrentYear: () => setState(() {
            selectedYear = now.year;
            selectedMonth = null;
            selectedBudgetMonth = null;
          }),
          onAll: () => setState(() {
            selectedYear = null;
            selectedMonth = null;
            selectedBudgetMonth = null;
          }),
          onYearChanged: (value) => setState(() {
            selectedYear = value;
            if (value == null) {
              selectedMonth = null;
            }
            selectedBudgetMonth = null;
          }),
          onMonthChanged: selectedYear == null
              ? null
              : (value) => setState(() {
                    selectedMonth = value;
                    selectedBudgetMonth = null;
                  }),
        ),
        const SizedBox(height: 12),
        _DashboardKpiGrid(
          items: [
            _DashboardKpiData(
              label: '总资产',
              amount: totalAssets,
              color: const Color(0xFF5B9BD5),
            ),
            _DashboardKpiData(
              label: '期间结余',
              amount: income - expense,
              color: income - expense >= 0
                  ? const Color(0xFF6AAF8A)
                  : const Color(0xFFE07B7B),
            ),
            _DashboardKpiData(
              label: '期间收入',
              amount: income,
              color: const Color(0xFF6AAF8A),
            ),
            _DashboardKpiData(
              label: '期间支出',
              amount: expense,
              color: const Color(0xFFE07B7B),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '资产组成',
          subtitle: '截至 ${monthLabel(monthKeyFromDate(assetEnd))}',
          child: _DashboardKpiGrid(
            compact: true,
            items: [
              _DashboardKpiData(
                label: '现金余额',
                amount: cashTotal,
                color: const Color(0xFF5B9BD5),
              ),
              _DashboardKpiData(
                label: '信用负债',
                amount: creditTotal,
                color: const Color(0xFFE07B7B),
              ),
              _DashboardKpiData(
                label: '投资余额',
                amount: investmentTotal,
                color: const Color(0xFF6AAF8A),
              ),
              _DashboardKpiData(
                label: '退休余额',
                amount: retirementTotal,
                color: const Color(0xFFE8A838),
              ),
            ],
          ),
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
                value: activeBudgetMonth,
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
              Text(
                '总支出 / 总预算: ${formatMoney(totalBudgetExpense)} / ${formatMoney(totalBudget)}',
              ),
              Text(
                '预计支出: ${formatMoney(repository.totalPlannedBudgetExpenseForMonth(activeBudgetMonth))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (activeBudgets.isEmpty)
                Text(
                  '该月份还没有预算规则。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ...sortedActiveBudgets.map((budget) {
                final effectiveBudget = repository.effectiveBudgetForMonth(
                  budget,
                  activeBudgetMonth,
                );
                final spent = repository.expenseTotalForCategory(
                  budget.categoryId,
                  activeBudgetMonth,
                );
                final planned = repository.plannedExpenseTotalForCategory(
                  budget.categoryId,
                  activeBudgetMonth,
                );
                final ratio =
                    effectiveBudget == 0 ? 0.0 : spent / effectiveBudget;
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
                        '实际 ${formatMoney(spent)} · 预计 ${formatMoney(planned)} · 预算 ${formatMoney(effectiveBudget)}',
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
            title: '未来现金流',
            subtitle: '按现金 + 信用账户估算，预计交易会参与预测',
            child: _PlanningOverview(
              forecast: forecast,
              futureExpenseReserve: futureExpenseReserve,
              futureMonthlySummaries: futureMonthlySummaries,
              cashFlowProjection: cashFlowProjection,
              creditReminders: creditReminders,
            ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                          Text(
                            transaction.description ??
                                transaction.merchant ??
                                _typeLabel(transaction.type),
                          ),
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
                        color: isExpense
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF15803D),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.86),
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.description ??
                                        transaction.merchant ??
                                        _typeLabel(transaction.type),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${repository.accountName(transaction.accountId)} · '
                                    '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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

  DateTime _resolveAnchorMonth() {
    if (selectedYear == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month);
    }
    if (selectedMonth == null) {
      final now = DateTime.now();
      final anchorMonth = selectedYear == now.year ? now.month : 12;
      return DateTime(selectedYear!, anchorMonth);
    }
    return DateTime(selectedYear!, selectedMonth!);
  }

  String _activeQuickRangeLabel(DateTime now) {
    if (selectedYear == null) {
      return '全部';
    }
    if (selectedYear == now.year && selectedMonth == now.month) {
      return '本月';
    }
    final previousMonth = DateTime(now.year, now.month - 1);
    if (selectedYear == previousMonth.year &&
        selectedMonth == previousMonth.month) {
      return '上月';
    }
    if (selectedYear == now.year && selectedMonth == null) {
      return '今年';
    }
    return '自选';
  }

  double _budgetUsageRatio(
    FinanceRepository repository,
    Budget budget,
    String monthKey,
  ) {
    final effectiveBudget = repository.effectiveBudgetForMonth(
      budget,
      monthKey,
    );
    if (effectiveBudget <= 0) {
      return 0;
    }
    final spent = repository.expenseTotalForCategory(
      budget.categoryId,
      monthKey,
    );
    return spent / effectiveBudget;
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

  double _balanceForGroup(
    FinanceRepository repository,
    ReportGroup group,
    DateTime endDate,
  ) {
    return repository.accounts
        .where((account) => account.reportGroup == group)
        .fold<double>(
          0,
          (sum, account) =>
              sum + _balanceForAccount(repository, account, endDate),
        );
  }

  double _balanceForAccount(
    FinanceRepository repository,
    Account account,
    DateTime endDate,
  ) {
    return repository.accountBalanceAtBase(account.id, endDate);
  }

  ForecastSummary _forecastFromSummaries(
    List<MonthlySummary> summaries,
    FinanceRepository repository,
  ) {
    final activeSummaries = summaries
        .where((item) => item.income != 0 || item.expense != 0)
        .toList();
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
        activeSummaries.fold<double>(0, (sum, item) => sum + item.income) /
            activeSummaries.length;
    final averageExpense =
        activeSummaries.fold<double>(0, (sum, item) => sum + item.expense) /
            activeSummaries.length;
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

class _DashboardRangeSelector extends StatelessWidget {
  const _DashboardRangeSelector({
    required this.activeQuickRange,
    required this.selectedYear,
    required this.selectedMonth,
    required this.years,
    required this.months,
    required this.onCurrentMonth,
    required this.onPreviousMonth,
    required this.onCurrentYear,
    required this.onAll,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  final String activeQuickRange;
  final int? selectedYear;
  final int? selectedMonth;
  final List<int> years;
  final List<int> months;
  final VoidCallback onCurrentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onCurrentYear;
  final VoidCallback onAll;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?>? onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '时间范围',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickRangeChip(
                label: '本月',
                selected: activeQuickRange == '本月',
                onSelected: onCurrentMonth,
              ),
              _QuickRangeChip(
                label: '上月',
                selected: activeQuickRange == '上月',
                onSelected: onPreviousMonth,
              ),
              _QuickRangeChip(
                label: '今年',
                selected: activeQuickRange == '今年',
                onSelected: onCurrentYear,
              ),
              _QuickRangeChip(
                label: '全部',
                selected: activeQuickRange == '全部',
                onSelected: onAll,
              ),
              if (activeQuickRange == '自选')
                _QuickRangeChip(label: '自选', selected: true, onSelected: () {}),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: selectedYear,
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
                  onChanged: onYearChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: selectedMonth,
                  decoration: const InputDecoration(
                    labelText: '月份',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('全年'),
                    ),
                    ...months.map(
                      (month) => DropdownMenuItem<int?>(
                        value: month,
                        child: Text(month.toString().padLeft(2, '0')),
                      ),
                    ),
                  ],
                  onChanged: onMonthChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickRangeChip extends StatelessWidget {
  const _QuickRangeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DashboardKpiData {
  const _DashboardKpiData({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

class _DashboardKpiGrid extends StatelessWidget {
  const _DashboardKpiGrid({required this.items, this.compact = false});

  final List<_DashboardKpiData> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final spacing = compact ? 8.0 : 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _DashboardKpiCard(item: item, compact: compact),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DashboardKpiCard extends StatelessWidget {
  const _DashboardKpiCard({required this.item, required this.compact});

  final _DashboardKpiData item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 11 : 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.label, style: theme.textTheme.labelSmall),
              ),
              Text(
                currencyLabel(activeBaseCurrencyCode),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            item.amount < 0
                ? '-${formatMoneyValue(item.amount)}'
                : formatMoneyValue(item.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              color: item.color,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        _MatrixRow(
          label: firstLabel,
          values: summaries.map((item) => formatMoney(item.income)).toList(),
        ),
        _MatrixRow(
          label: secondLabel,
          values: summaries.map((item) => formatMoney(item.expense)).toList(),
        ),
        _MatrixRow(
          label: thirdLabel,
          values: summaries.map((item) => formatMoney(item.net)).toList(),
        ),
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

class _PlanningOverview extends StatelessWidget {
  const _PlanningOverview({
    required this.forecast,
    required this.futureExpenseReserve,
    required this.futureMonthlySummaries,
    required this.cashFlowProjection,
    required this.creditReminders,
  });

  final ForecastSummary forecast;
  final double futureExpenseReserve;
  final List<MonthlySummary> futureMonthlySummaries;
  final List<CashFlowProjectionPoint> cashFlowProjection;
  final List<CreditCardPaymentReminder> creditReminders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardKpiGrid(
          compact: true,
          items: [
            _DashboardKpiData(
              label: '未来3个月预留',
              amount: futureExpenseReserve,
              color: const Color(0xFFE8A838),
            ),
            _DashboardKpiData(
              label: '月均结余',
              amount: forecast.averageMonthlySavings,
              color: forecast.averageMonthlySavings >= 0
                  ? const Color(0xFF6AAF8A)
                  : const Color(0xFFE07B7B),
            ),
            _DashboardKpiData(
              label: '3个月后储蓄',
              amount: forecast.projectedSavingsInThreeMonths,
              color: const Color(0xFF5B9BD5),
            ),
            _DashboardKpiData(
              label: '6个月后储蓄',
              amount: forecast.projectedSavingsInSixMonths,
              color: const Color(0xFF5B9BD5),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('未来三个月', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _MonthlyMatrix(
          summaries: futureMonthlySummaries,
          firstLabel: '收入',
          secondLabel: '支出',
          thirdLabel: '结余',
        ),
        const SizedBox(height: 14),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 10),
        Text('现金流推演', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _CashFlowProjectionView(points: cashFlowProjection),
        const SizedBox(height: 10),
        Divider(color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 10),
        Text('信用卡还款提醒', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (creditReminders.isEmpty)
          Text('暂无需要提醒的信用卡余额', style: Theme.of(context).textTheme.bodySmall)
        else
          Column(
            children: creditReminders
                .map((item) => _CreditReminderTile(reminder: item))
                .toList(),
          ),
      ],
    );
  }
}

class _CashFlowProjectionView extends StatelessWidget {
  const _CashFlowProjectionView({required this.points});

  final List<CashFlowProjectionPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('暂无预测数据');
    }
    return Column(
      children: points.map((point) {
        final netColor =
            point.net >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(monthLabel(point.monthKey))),
              Expanded(
                child: Text(
                  '收 ${formatMoney(point.income)} · 支 ${formatMoney(point.expense)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                formatMoney(point.net),
                style: TextStyle(color: netColor, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Text(formatMoney(point.endingCash)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CreditReminderTile extends StatelessWidget {
  const _CreditReminderTile({required this.reminder});

  final CreditCardPaymentReminder reminder;

  @override
  Widget build(BuildContext context) {
    final dueDate =
        '${reminder.dueDate.year}-${reminder.dueDate.month.toString().padLeft(2, '0')}-${reminder.dueDate.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).cardColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${reminder.account.name} · 建议还款日 $dueDate',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            formatMoney(
              reminder.amountDue,
              currency: reminder.account.currency,
            ),
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
