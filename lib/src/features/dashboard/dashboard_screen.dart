import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/forecast_summary.dart';
import '../../core/models/monthly_summary.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    final monthKey = monthKeyFromDate(DateTime.now());
    final budgetMonthKeys = repository.transactions
        .map((item) => monthKeyFromDate(item.transactionDate))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final selectedBudgetMonth = budgetMonthKeys.isEmpty ? monthKey : budgetMonthKeys.first;
    final cashTotal = repository.totalAssetsByGroup(ReportGroup.cash);
    final creditTotal = repository.totalAssetsByGroup(ReportGroup.credit);
    final investmentTotal = repository.totalAssetsByGroup(ReportGroup.investment);
    final retirementTotal = repository.totalAssetsByGroup(ReportGroup.retirement);
    final income = repository.totalIncomeForMonth(monthKey);
    final expense = repository.totalExpenseForMonth(monthKey);
    final monthlySummaries = repository.monthlySummaries(months: 4);
    final futureExpenseReserve = repository.totalFutureExpense(monthsAhead: 3);
    final futureMonthlySummaries = repository.futureExpenseSummaries(months: 3);
    final upcomingExpenses = repository.upcomingExpenseTransactions();
    final forecast = repository.forecastSummary();
    final totalBudget = repository.totalEffectiveBudgetForMonth(selectedBudgetMonth);
    final totalBudgetExpense = repository.totalBudgetExpenseForMonth(selectedBudgetMonth);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenHeader(title: '总览'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _MetricCard(label: '现金', amount: cashTotal),
            _MetricCard(label: '信用', amount: creditTotal),
            _MetricCard(label: '投资', amount: investmentTotal),
            _MetricCard(label: '退休', amount: retirementTotal),
            _MetricCard(label: '本月收入', amount: income),
            _MetricCard(label: '本月支出', amount: expense),
            _MetricCard(label: '未来3月预留', amount: futureExpenseReserve),
            _MetricCard(label: '总资产', amount: repository.totalAssets()),
            _MetricCard(label: '净资产', amount: repository.totalAssets(includeCredit: false)),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '月度对比',
          child: _MonthlyMatrix(summaries: monthlySummaries),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '储蓄预测',
          child: _ForecastView(forecast: forecast),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '未来支出',
          child: Column(
            children: futureMonthlySummaries
                .map(
                  (summary) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 70, child: Text(monthLabel(summary.monthKey))),
                        Expanded(child: Text('预留 ${formatMoney(summary.expense)}')),
                        Expanded(child: Text('结余 ${formatMoney(summary.net)}')),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '预算监控',
          subtitle: '结转会把上月未用完预算带到下月',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('统计月份：${monthLabel(selectedBudgetMonth)}'),
              const SizedBox(height: 6),
              Text('总支出 / 总预算：${formatMoney(totalBudgetExpense)} / ${formatMoney(totalBudget)}'),
              const SizedBox(height: 12),
              ...repository.activeBudgetsForMonth(selectedBudgetMonth).map((budget) {
                final effectiveBudget = repository.effectiveBudgetForMonth(budget, selectedBudgetMonth);
                final spent = repository.expenseTotalForCategory(
                  budget.categoryId,
                  selectedBudgetMonth,
                );
                final ratio = effectiveBudget == 0 ? 0.0 : spent / effectiveBudget;
                final color = ratio > 1
                    ? Colors.red
                    : ratio >= budget.alertThreshold
                        ? Colors.orange
                        : Colors.green;
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
        const SizedBox(height: 16),
        SectionCard(
          title: '最近交易',
          child: Column(
            children: repository.recentTransactions().map((transaction) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  transaction.description ?? transaction.merchant ?? transaction.type.name,
                ),
                subtitle: Text(repository.accountName(transaction.accountId)),
                trailing: Text(
                  formatMoney(transaction.amount, currency: transaction.currency),
                ),
              );
            }).toList(),
          ),
        ),
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
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        transaction.description ?? transaction.merchant ?? transaction.type.name,
                      ),
                      subtitle: Text(
                        '${repository.accountName(transaction.accountId)} • '
                        '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: Text(
                        formatMoney(transaction.amount, currency: transaction.currency),
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
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
              Expanded(
                child: Text(label, style: theme.textTheme.labelLarge),
              ),
              Text(
                currencyLabel('MYR'),
                style: theme.textTheme.bodySmall,
              ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyMatrix extends StatelessWidget {
  const _MonthlyMatrix({required this.summaries});

  final List<MonthlySummary> summaries;

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
        _MatrixRow(label: '收入', values: summaries.map((item) => formatMoney(item.income)).toList()),
        _MatrixRow(label: '支出', values: summaries.map((item) => formatMoney(item.expense)).toList()),
        _MatrixRow(label: '结余', values: summaries.map((item) => formatMoney(item.net)).toList()),
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
        Text('平均收入：${formatMoney(forecast.averageMonthlyIncome)}'),
        const SizedBox(height: 6),
        Text('平均支出：${formatMoney(forecast.averageMonthlyExpense)}'),
        const SizedBox(height: 6),
        Text('月均结余：${formatMoney(forecast.averageMonthlySavings)}'),
        const SizedBox(height: 10),
        Text('3个月后预计储蓄：${formatMoney(forecast.projectedSavingsInThreeMonths)}'),
        const SizedBox(height: 6),
        Text('6个月后预计储蓄：${formatMoney(forecast.projectedSavingsInSixMonths)}'),
      ],
    );
  }
}
