import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/category.dart';
import '../../core/models/monthly_summary.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
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
    final currentMonthKey = monthKeyFromDate(DateTime.now());
    final monthKeys = _monthKeys();
    final monthlySummaries = repository
        .monthlySummaries(
          months: rangeType == ReportRangeType.last12Months ? 12 : DateTime.now().month,
        )
        .where((item) => monthKeys.contains(item.monthKey))
        .where((item) => item.income != 0 || item.expense != 0)
        .toList();
    final totalExpense = monthlySummaries.fold<double>(0, (sum, item) => sum + item.expense);
    final totalIncome = monthlySummaries.fold<double>(0, (sum, item) => sum + item.income);
    final expenseByCategory = repository.categoryTotalsForMonths(
      type: CategoryType.expense,
      monthKeys: monthlySummaries.map((item) => item.monthKey).toList(),
    );
    final categoryPoints = expenseByCategory.entries
        .where((entry) => entry.value > 0)
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
    final budgetMonth = monthlySummaries.isEmpty ? currentMonthKey : monthlySummaries.last.monthKey;
    final activeBudgets = repository.activeBudgetsForMonth(budgetMonth);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '报表',
          actions: [
            DropdownButton<ReportRangeType>(
              value: rangeType,
              items: const [
                DropdownMenuItem(
                  value: ReportRangeType.last12Months,
                  child: Text('近 12 个月'),
                ),
                DropdownMenuItem(
                  value: ReportRangeType.currentYear,
                  child: Text('本年度'),
                ),
              ],
              onChanged: (value) => setState(() => rangeType = value!),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SegmentedButton<ReportViewType>(
          segments: const [
            ButtonSegment(value: ReportViewType.line, label: Text('线图')),
            ButtonSegment(value: ReportViewType.pie, label: Text('饼图')),
            ButtonSegment(value: ReportViewType.table, label: Text('表格')),
          ],
          selected: {viewType},
          onSelectionChanged: (selection) {
            setState(() => viewType = selection.first);
          },
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '期间汇总',
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('收入 ${formatMoney(totalIncome)}'),
              Text('支出 ${formatMoney(totalExpense)}'),
              Text('结余 ${formatMoney(totalIncome - totalExpense)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '支出视图',
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
          title: '预算状态',
          subtitle: monthLabel(budgetMonth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '总支出 / 总预算：${formatMoney(repository.totalBudgetExpenseForMonth(budgetMonth))} / '
                '${formatMoney(repository.totalEffectiveBudgetForMonth(budgetMonth))}',
              ),
              const SizedBox(height: 10),
              if (activeBudgets.isEmpty) const Text('暂无预算数据'),
              ...activeBudgets.map((budget) {
                final effective = repository.effectiveBudgetForMonth(budget, budgetMonth);
                final spent = repository.expenseTotalForCategory(budget.categoryId, budgetMonth);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(repository.categoryName(budget.categoryId))),
                      Text('${formatMoney(spent)} / ${formatMoney(effective)}'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '资产分组',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('总资产 ${formatMoney(repository.totalAssets())}'),
              const SizedBox(height: 6),
              Text('净资产 ${formatMoney(repository.totalAssets(includeCredit: false))}'),
              const SizedBox(height: 10),
              ...ReportGroup.values.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${_groupLabel(group)} ${formatMoney(repository.totalAssetsByGroup(group))}',
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'AI 分析数据',
          child: SelectableText(
            '{\n'
            '  "month": "$currentMonthKey",\n'
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
        return SimpleLineChart(
          points: linePoints,
          amountBuilder: (value) => formatMoney(value),
        );
      case ReportViewType.pie:
        return SimplePieLegend(
          points: categoryPoints,
          amountBuilder: (value) => formatMoney(value),
        );
      case ReportViewType.table:
        return _MonthlyMatrix(
          summaries: monthlySummaries,
          firstLabel: '收入',
          secondLabel: '支出',
          thirdLabel: '结余',
        );
    }
  }

  String _groupLabel(ReportGroup group) {
    switch (group) {
      case ReportGroup.cash:
        return '现金';
      case ReportGroup.credit:
        return '信用';
      case ReportGroup.investment:
        return '投资';
      case ReportGroup.retirement:
        return '退休';
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

class _MonthlyMatrix extends StatelessWidget {
  const _MonthlyMatrix({
    required this.summaries,
    required this.firstLabel,
    required this.secondLabel,
    required this.thirdLabel,
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
