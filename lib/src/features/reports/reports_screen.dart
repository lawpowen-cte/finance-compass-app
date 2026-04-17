import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/category.dart';
import '../../core/models/monthly_summary.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_range.dart';
import '../../core/utils/month_key.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import '../shared/simple_charts.dart';

enum ReportViewType { line, pie, table }
enum ReportRangeType { last12Months, currentYear }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportViewType viewType = ReportViewType.line;
  ReportRangeType rangeType = ReportRangeType.last12Months;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final monthKey = monthKeyFromDate(DateTime.now());
    final monthKeys = _monthKeys();
    final monthlySummaries = repository
        .monthlySummaries(months: rangeType == ReportRangeType.last12Months ? 12 : DateTime.now().month)
        .where((item) => monthKeys.contains(item.monthKey))
        .toList();
    final totalExpense = monthlySummaries.fold<double>(0, (sum, item) => sum + item.expense);
    final totalIncome = monthlySummaries.fold<double>(0, (sum, item) => sum + item.income);
    final expenseByCategory = repository.categoryTotalsForMonths(
      type: CategoryType.expense,
      monthKeys: monthKeys,
    );
    final categoryPoints = expenseByCategory.entries
        .map(
          (entry) => ChartPoint(
            label: repository.categoryName(entry.key),
            value: entry.value,
            color: _palette(entry.key),
          ),
        )
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final linePoints = monthlySummaries
        .map((item) => ChartPoint(label: monthLabel(item.monthKey), value: item.expense))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: 'Reports',
          actions: [
            DropdownButton<ReportRangeType>(
              value: rangeType,
              items: const [
                DropdownMenuItem(
                  value: ReportRangeType.last12Months,
                  child: Text('Last 12 months'),
                ),
                DropdownMenuItem(
                  value: ReportRangeType.currentYear,
                  child: Text('Current year'),
                ),
              ],
              onChanged: (value) => setState(() => rangeType = value!),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<ReportViewType>(
          segments: const [
            ButtonSegment(value: ReportViewType.line, label: Text('Line')),
            ButtonSegment(value: ReportViewType.pie, label: Text('Pie')),
            ButtonSegment(value: ReportViewType.table, label: Text('Table')),
          ],
          selected: {viewType},
          onSelectionChanged: (selection) {
            setState(() => viewType = selection.first);
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Monthly Summary',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Income: ${formatMoney(totalIncome)}'),
              const SizedBox(height: 6),
              Text('Expense: ${formatMoney(totalExpense)}'),
              const SizedBox(height: 6),
              Text('Net: ${formatMoney(totalIncome - totalExpense)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Expense View',
          child: _buildChart(
            context,
            viewType: viewType,
            linePoints: linePoints,
            categoryPoints: categoryPoints.take(6).toList(),
            monthlySummaries: monthlySummaries,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Budget Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: repository.budgets.map((budget) {
              final spent = repository.expenseTotalForCategory(budget.categoryId, budget.monthKey);
              final variance = budget.amount - spent;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${repository.categoryName(budget.categoryId)} (${budget.monthKey}): ${formatMoney(variance)} remaining',
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Group Totals',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ReportGroup.values.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${group.name}: ${formatMoney(repository.totalAssetsByGroup(group))}',
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'AI Payload Preview',
          child: SelectableText(
            '{\n'
            '  "month": "$monthKey",\n'
            '  "income": $totalIncome,\n'
            '  "expense": $totalExpense,\n'
            '  "net": ${totalIncome - totalExpense},\n'
              '  "assets_by_group": {\n'
            '    "cash": ${repository.totalAssetsByGroup(ReportGroup.cash)},\n'
            '    "credit": ${repository.totalAssetsByGroup(ReportGroup.credit)},\n'
            '    "investment": ${repository.totalAssetsByGroup(ReportGroup.investment)},\n'
            '    "retirement": ${repository.totalAssetsByGroup(ReportGroup.retirement)}\n'
            '  }\n'
            '}',
          ),
        ),
      ],
    );
  }

  List<String> _monthKeys() {
    if (rangeType == ReportRangeType.last12Months) {
      return recentMonthKeys(count: 12);
    }
    return List.generate(DateTime.now().month, (index) {
      final date = DateTime(DateTime.now().year, index + 1);
      return monthKeyFromDate(date);
    });
  }

  Widget _buildChart(
    BuildContext context, {
    required ReportViewType viewType,
    required List<ChartPoint> linePoints,
    required List<ChartPoint> categoryPoints,
    required List<MonthlySummary> monthlySummaries,
  }) {
    switch (viewType) {
      case ReportViewType.line:
        return SimpleLineChart(points: linePoints);
      case ReportViewType.pie:
        return SimplePieLegend(points: categoryPoints);
      case ReportViewType.table:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SimpleBarTable(points: linePoints),
            const SizedBox(height: 16),
            ...monthlySummaries.map((summary) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${monthLabel(summary.monthKey)} | income ${formatMoney(summary.income)} | '
                  'expense ${formatMoney(summary.expense)} | net ${formatMoney(summary.net)}',
                ),
              );
            }),
          ],
        );
    }
  }

  Color _palette(String seed) {
    final colors = [
      const Color(0xFF0F766E),
      const Color(0xFF2563EB),
      const Color(0xFFDC2626),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }
}
