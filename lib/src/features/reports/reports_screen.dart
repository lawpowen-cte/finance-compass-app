import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/data/finance_repository.dart';
import '../../core/services/ai_analysis_service.dart';
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
enum ReportRangeType { last3Months, last6Months, last12Months, currentYear }
enum ReportMeasureMode { monthly, cumulative }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportViewType viewType = ReportViewType.line;
  ReportRangeType rangeType = ReportRangeType.last6Months;
  ReportMeasureMode measureMode = ReportMeasureMode.monthly;
  String? _aiHtml;
  bool _aiLoading = false;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final now = DateTime.now();
    final currentMonthKey = monthKeyFromDate(now);
    final monthKeys = _monthKeysForRange(rangeType, now);
    final rawSummaries = monthKeys
        .map(
          (monthKey) => MonthlySummary(
            monthKey: monthKey,
            income: repository.totalIncomeForMonth(monthKey),
            expense: repository.totalExpenseForMonth(monthKey),
          ),
        )
        .toList();
    final displaySummaries = measureMode == ReportMeasureMode.monthly
        ? rawSummaries
        : _toCumulativeSummaries(rawSummaries);

    final totalExpense = rawSummaries.fold<double>(0, (sum, item) => sum + item.expense);
    final totalIncome = rawSummaries.fold<double>(0, (sum, item) => sum + item.income);
    final expenseByCategory = repository.categoryTotalsForMonths(
      type: CategoryType.expense,
      monthKeys: monthKeys,
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

    final budgetMonth = currentMonthKey;
    final activeBudgets = repository.activeBudgetsForMonth(budgetMonth);
    final futureMonthFlags = monthKeys.map((monthKey) => _isFutureMonth(monthKey, now)).toList();

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
                  value: ReportRangeType.last3Months,
                  child: Text('近 3 个月'),
                ),
                DropdownMenuItem(
                  value: ReportRangeType.last6Months,
                  child: Text('近 6 个月'),
                ),
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
        Row(
          children: [
            Expanded(
              child: SegmentedButton<ReportViewType>(
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
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<ReportMeasureMode>(
                segments: const [
                  ButtonSegment(value: ReportMeasureMode.monthly, label: Text('单月')),
                  ButtonSegment(value: ReportMeasureMode.cumulative, label: Text('累计')),
                ],
                selected: {measureMode},
                onSelectionChanged: (selection) {
                  setState(() => measureMode = selection.first);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _aiLoading
                    ? null
                    : () async {
                        final repo = widget.repository;
                        final gatewayUrl = repo.aiGatewayUrl;
                        if (gatewayUrl.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请先在设置中配置 AI 网关地址')),
                            );
                          }
                          return;
                        }
                        setState(() {
                          _aiLoading = true;
                          _aiHtml = null;
                        });
                        try {
                          final service = AiAnalysisService(
                            gatewayUrl: gatewayUrl,
                          );
                          final html = await service.generateAnalysis(repo);
                          if (mounted) {
                            setState(() => _aiHtml = html);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final msg = e is AiNetworkException
                                ? e.message
                                : 'AI 分析失败：$e';
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('AI 分析失败'),
                                content: Text(msg, style: const TextStyle(fontSize: 14)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('确定'),
                                  ),
                                ],
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _aiLoading = false);
                          }
                        }
                      },
                icon: _aiLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('AI 分析'),
              ),
            ),
          ],
        ),
        if (_aiHtml != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 500,
            child: _AiWebView(html: _aiHtml!),
          ),
        ],
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
          title: '收入 / 支出',
          subtitle: rangeType == ReportRangeType.currentYear
              ? '未来月份会用浅色标记'
              : null,
          child: _buildChart(
            context,
            viewType: viewType,
            summaries: displaySummaries,
            rawSummaries: rawSummaries,
            futureMonthFlags: futureMonthFlags,
            categoryPoints: categoryPoints.take(6).toList(),
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

  List<String> _monthKeysForRange(ReportRangeType rangeType, DateTime now) {
    switch (rangeType) {
      case ReportRangeType.last3Months:
        return recentMonthKeys(count: 3, anchor: now);
      case ReportRangeType.last6Months:
        return recentMonthKeys(count: 6, anchor: now);
      case ReportRangeType.last12Months:
        return recentMonthKeys(count: 12, anchor: now);
      case ReportRangeType.currentYear:
        return List.generate(12, (index) {
          final date = DateTime(now.year, index + 1);
          return monthKeyFromDate(date);
        });
    }
  }

  List<MonthlySummary> _toCumulativeSummaries(List<MonthlySummary> input) {
    var runningIncome = 0.0;
    var runningExpense = 0.0;
    return input.map((summary) {
      runningIncome += summary.income;
      runningExpense += summary.expense;
      return MonthlySummary(
        monthKey: summary.monthKey,
        income: runningIncome,
        expense: runningExpense,
      );
    }).toList();
  }

  bool _isFutureMonth(String monthKey, DateTime now) {
    final nowKey = monthKeyFromDate(DateTime(now.year, now.month));
    return monthKey.compareTo(nowKey) > 0;
  }

  Widget _buildChart(
    BuildContext context, {
    required ReportViewType viewType,
    required List<MonthlySummary> summaries,
    required List<MonthlySummary> rawSummaries,
    required List<bool> futureMonthFlags,
    required List<ChartPoint> categoryPoints,
  }) {
    switch (viewType) {
      case ReportViewType.line:
        return _IncomeExpenseLineChart(
          summaries: summaries,
          futureMonthFlags: futureMonthFlags,
        );
      case ReportViewType.pie:
        return SimplePieLegend(
          points: categoryPoints,
          amountBuilder: (value) => formatMoney(value),
        );
      case ReportViewType.table:
        return _MonthlyMatrix(
          summaries: summaries,
          futureMonthFlags: futureMonthFlags,
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

// ── AI WebView helper ─────────────────────────────────────────────────
class _AiWebView extends StatefulWidget {
  const _AiWebView({required this.html});
  final String html;

  @override
  State<_AiWebView> createState() => _AiWebViewState();
}

class _AiWebViewState extends State<_AiWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: WebViewWidget(controller: _controller),
    );
  }
}

// ── Existing helper widgets ────────────────────────────────────────────
class _IncomeExpenseLineChart extends StatelessWidget {
  const _IncomeExpenseLineChart({
    required this.summaries,
    required this.futureMonthFlags,
  });

  final List<MonthlySummary> summaries;
  final List<bool> futureMonthFlags;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('暂无数据')));
    }

    final maxValue = summaries.fold<double>(
      0,
      (max, item) => math.max(max, math.max(item.income, item.expense)),
    );

    return SizedBox(
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendChip(label: '收入', color: Color(0xFF15803D)),
              _LegendChip(label: '支出', color: Color(0xFFB91C1C)),
              _LegendChip(label: '未来月份', color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (index) {
                      final ratio = (3 - index) / 3;
                      final value = maxValue * ratio;
                      return Text(
                        formatMoney(value),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _IncomeExpenseLinePainter(
                      summaries: summaries,
                      futureMonthFlags: futureMonthFlags,
                      maxValue: maxValue == 0 ? 1 : maxValue,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 72),
              ...summaries.asMap().entries.map(
                (entry) => Expanded(
                  child: Text(
                    monthLabel(entry.value.monthKey),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: futureMonthFlags[entry.key]
                              ? const Color(0xFF64748B)
                              : null,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseLinePainter extends CustomPainter {
  _IncomeExpenseLinePainter({
    required this.summaries,
    required this.futureMonthFlags,
    required this.maxValue,
  });

  final List<MonthlySummary> summaries;
  final List<bool> futureMonthFlags;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    const left = 8.0;
    final width = size.width - left - 12;
    final height = size.height - 12;

    for (var i = 1; i <= 3; i++) {
      final y = height - ((height - 12) * (i / 4));
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(left, height), Offset(size.width, height), axisPaint);
    canvas.drawLine(const Offset(left, 0), Offset(left, height), axisPaint);

    _drawSeries(
      canvas,
      width: width,
      height: height,
      left: left,
      values: summaries.map((item) => item.income).toList(),
      baseColor: const Color(0xFF15803D),
    );
    _drawSeries(
      canvas,
      width: width,
      height: height,
      left: left,
      values: summaries.map((item) => item.expense).toList(),
      baseColor: const Color(0xFFB91C1C),
    );
  }

  void _drawSeries(
    Canvas canvas, {
    required double width,
    required double height,
    required double left,
    required List<double> values,
    required Color baseColor,
  }) {
    for (var i = 0; i < values.length - 1; i++) {
      final startOffset = _pointOffset(i, values[i], width, height, left);
      final endOffset = _pointOffset(i + 1, values[i + 1], width, height, left);
      final isFutureSegment = futureMonthFlags[i] || futureMonthFlags[i + 1];
      final segmentPaint = Paint()
        ..color = isFutureSegment ? baseColor.withValues(alpha: 0.45) : baseColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(startOffset, endOffset, segmentPaint);
    }

    for (var i = 0; i < values.length; i++) {
      final offset = _pointOffset(i, values[i], width, height, left);
      final pointPaint = Paint()
        ..color = futureMonthFlags[i] ? baseColor.withValues(alpha: 0.45) : baseColor;
      canvas.drawCircle(offset, 3.5, pointPaint);
    }
  }

  Offset _pointOffset(int index, double value, double width, double height, double left) {
    final dx = left + (width * (summaries.length == 1 ? 0 : index / (summaries.length - 1)));
    final dy = height - ((value / maxValue) * (height - 12));
    return Offset(dx, dy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _MonthlyMatrix extends StatelessWidget {
  const _MonthlyMatrix({
    required this.summaries,
    required this.futureMonthFlags,
    required this.firstLabel,
    required this.secondLabel,
    required this.thirdLabel,
  });

  final List<MonthlySummary> summaries;
  final List<bool> futureMonthFlags;
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
            ...summaries.asMap().entries.map(
              (entry) => Expanded(
                child: Text(
                  monthLabel(entry.value.monthKey),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: futureMonthFlags[entry.key]
                            ? const Color(0xFF64748B)
                            : null,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MatrixRow(
          label: firstLabel,
          values: summaries.map((item) => formatMoney(item.income)).toList(),
          futureMonthFlags: futureMonthFlags,
        ),
        _MatrixRow(
          label: secondLabel,
          values: summaries.map((item) => formatMoney(item.expense)).toList(),
          futureMonthFlags: futureMonthFlags,
        ),
        _MatrixRow(
          label: thirdLabel,
          values: summaries.map((item) => formatMoney(item.net)).toList(),
          futureMonthFlags: futureMonthFlags,
        ),
      ],
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({
    required this.label,
    required this.values,
    required this.futureMonthFlags,
  });

  final String label;
  final List<String> values;
  final List<bool> futureMonthFlags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(label)),
          ...values.asMap().entries.map(
            (entry) => Expanded(
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: futureMonthFlags[entry.key]
                          ? const Color(0xFF64748B)
                          : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
