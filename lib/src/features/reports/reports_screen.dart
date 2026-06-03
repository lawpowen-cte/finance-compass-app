import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/data/finance_repository.dart';
import '../../core/providers/ai_analysis_provider.dart';
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

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportViewType viewType = ReportViewType.line;
  ReportRangeType rangeType = ReportRangeType.last6Months;
  ReportMeasureMode measureMode = ReportMeasureMode.monthly;

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
              child: _AiAnalysisButton(),
            ),
          ],
        ),
        _AiResultDisplay(),
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
/// AI 分析结果展示 + 弹窗监听
class _AiResultDisplay extends ConsumerStatefulWidget {
  const _AiResultDisplay();

  @override
  ConsumerState<_AiResultDisplay> createState() => _AiResultDisplayState();
}

class _AiResultDisplayState extends ConsumerState<_AiResultDisplay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 如果已分析完成（用户离开期间完成），直接弹窗
      final current = ref.read(aiAnalysisProvider);
      if (current.completed && current.html != null) {
        ref.read(aiAnalysisProvider.notifier).dismissCompleted();
        _showCompletedDialog();
      }

      ref.listen<AiAnalysisState>(aiAnalysisProvider, (prev, next) {
        if (next.completed && next.html != null) {
          ref.read(aiAnalysisProvider.notifier).dismissCompleted();
          _showCompletedDialog();
        }
        if (next.error != null && prev?.error == null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('❌ AI 分析失败'),
              content: Text(next.error!, style: const TextStyle(fontSize: 14)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(aiAnalysisProvider.notifier).clearError();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      });
    });
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ 分析完成'),
        content: const Text('AI 财务分析报告已生成，向下滚动查看。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('查看'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiAnalysisProvider);
    if (aiState.html != null) {
      return Container(
        margin: const EdgeInsets.only(top: 16, bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 8),
              child: Text(
                '🤖 AI 分析报告',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            // WebView 满宽，高度自适应
            _AiWebView(html: aiState.html!),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// AI 分析按钮，使用全局 provider
class _AiAnalysisButton extends ConsumerWidget {
  const _AiAnalysisButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiAnalysisProvider);

    return OutlinedButton.icon(
      onPressed: aiState.loading
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 AI 正在后台分析，完成后会通知你'),
                  duration: Duration(seconds: 3),
                ),
              );
              ref.read(aiAnalysisProvider.notifier).runAnalysis();
            },
      icon: aiState.loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome_outlined),
      label: Text(aiState.loading ? '分析中...' : 'AI 分析'),
    );
  }
}

class _AiWebView extends StatefulWidget {
  const _AiWebView({required this.html});
  final String html;

  @override
  State<_AiWebView> createState() => _AiWebViewState();
}

class _AiWebViewState extends State<_AiWebView> {
  late final WebViewController _controller;
  double _contentHeight = 520; // 初始高度

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterHeight', onMessageReceived: (msg) {
        final h = double.tryParse(msg.message);
        if (h != null && h > 0 && (h - _contentHeight).abs() > 2) {
          setState(() => _contentHeight = h);
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _injectHeightReporter(),
      ))
      ..loadHtmlString(widget.html);
  }

  void _injectHeightReporter() {
    _controller.runJavaScript('''
      (function() {
        function send() {
          var h = document.documentElement.scrollHeight || document.body.scrollHeight;
          FlutterHeight.postMessage(h.toString());
        }
        send();
        // 图片/CSS 加载后再测一次
        setTimeout(send, 300);
        setTimeout(send, 800);
        new MutationObserver(send).observe(document.body, {childList:true, subtree:true});
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _contentHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
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
