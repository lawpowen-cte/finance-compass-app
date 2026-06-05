import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/providers/ai_analysis_provider.dart';
import '../../core/models/account.dart';
import '../../core/models/monthly_summary.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../shared/finance_metric_card.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';

enum ReportRangeType { last3Months, last6Months, last12Months, currentYear }

enum ReportMeasureMode { monthly, cumulative }

enum DataFilterMode { actual, all }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRangeType rangeType = ReportRangeType.last6Months;
  ReportMeasureMode measureMode = ReportMeasureMode.monthly;
  DataFilterMode dataFilterMode = DataFilterMode.actual;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final now = DateTime.now();
    final currentMonthKey = monthKeyFromDate(now);
    final monthKeys = _monthKeysForRange(rangeType, now);
    final includePlanned = dataFilterMode == DataFilterMode.all;

    final rawSummaries = monthKeys
        .map(
          (monthKey) => MonthlySummary(
            monthKey: monthKey,
            income: repository.totalIncomeForMonth(monthKey) +
                (includePlanned
                    ? repository.plannedIncomeForMonth(monthKey)
                    : 0),
            expense: repository.totalExpenseForMonth(monthKey) +
                (includePlanned
                    ? repository.plannedExpenseForMonth(monthKey)
                    : 0),
          ),
        )
        .toList();
    final displaySummaries = measureMode == ReportMeasureMode.monthly
        ? rawSummaries
        : _toCumulativeSummaries(rawSummaries);

    final budgetMonth = currentMonthKey;
    final activeBudgets = repository.activeBudgetsForMonth(budgetMonth);
    final goalSummaries = repository.assetGoalSummaries();

    // 本月实际数据 (or actual+planned)
    final actualIncome = repository.totalIncomeForMonth(currentMonthKey) +
        (includePlanned
            ? repository.plannedIncomeForMonth(currentMonthKey)
            : 0);
    final actualExpense = repository.totalExpenseForMonth(currentMonthKey) +
        (includePlanned
            ? repository.plannedExpenseForMonth(currentMonthKey)
            : 0);

    // 累计数据（所选时间范围的总和）
    final cumulativeIncome =
        rawSummaries.fold<double>(0, (sum, s) => sum + s.income);
    final cumulativeExpense =
        rawSummaries.fold<double>(0, (sum, s) => sum + s.expense);

    // KPI 根据模式选择数据
    final kpiIncome = measureMode == ReportMeasureMode.cumulative
        ? cumulativeIncome
        : actualIncome;
    final kpiExpense = measureMode == ReportMeasureMode.cumulative
        ? cumulativeExpense
        : actualExpense;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ScreenHeader(
          title: '报表',
          subtitle: '按时间范围、统计口径和数据范围查看财务表现',
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '分析口径',
          subtitle:
              '${_rangeLabel(rangeType)} · ${_measureLabel(measureMode)} · ${_dataFilterLabel(dataFilterMode)}',
          child: _ReportControls(
            rangeType: rangeType,
            measureMode: measureMode,
            dataFilterMode: dataFilterMode,
            monthCount: _monthCountForRange(rangeType),
            onRangeChanged: (value) => setState(() => rangeType = value),
            onMeasureChanged: (value) => setState(() => measureMode = value),
            onDataFilterChanged: (value) =>
                setState(() => dataFilterMode = value),
          ),
        ),
        const _AiResultDisplay(),
        const SizedBox(height: 16),
        SectionCard(
          title: '总览',
          subtitle: measureMode == ReportMeasureMode.cumulative
              ? '所选时间范围累计'
              : '$currentMonthKey 本月表现',
          child: _KpiCards(
            totalAssets: repository.totalAssets(),
            monthlyIncome: kpiIncome,
            monthlyExpense: kpiExpense,
            isCumulative: measureMode == ReportMeasureMode.cumulative,
          ),
        ),
        const SizedBox(height: 16),

        // ── 目标进度条 ──
        if (goalSummaries.isNotEmpty) ...[
          SectionCard(
            title: '资产目标',
            child: Column(
              children: goalSummaries.map((g) {
                final pct = g.progressRatio * 100;
                final color = pct >= 100
                    ? const Color(0xFF6AAF8A)
                    : pct >= 50
                        ? const Color(0xFF5B9BD5)
                        : const Color(0xFFE8A838);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.goal.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${formatMoney(g.currentAssets)} / ${formatMoney(g.goal.targetAmount)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: math.min(g.progressRatio, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── 收支趋势 ──
        SectionCard(
          title: measureMode == ReportMeasureMode.monthly ? '收支趋势' : '累计趋势',
          subtitle: rangeType == ReportRangeType.currentYear
              ? '本年度，未来月份浅色标记'
              : _rangeLabel(rangeType),
          child: _MonthlyBarChart(
            summaries: displaySummaries,
            now: now,
          ),
        ),
        const SizedBox(height: 16),

        _ReportCardGrid(
          children: [
            SectionCard(
              title: '资产分布',
              subtitle: '按报表分组',
              child: _AssetDistributionPieChart(repository: repository),
            ),
            SectionCard(
              title: '账户明细',
              subtitle: '按当前月截止日',
              child: _AccountDetails(repository: repository),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── 预算状态 ──
        SectionCard(
          title: '预算执行',
          subtitle: monthLabel(budgetMonth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeBudgets.isEmpty)
                const Text('暂无预算数据', style: TextStyle(color: Colors.grey)),
              ...activeBudgets.map((budget) {
                final effective =
                    repository.effectiveBudgetForMonth(budget, budgetMonth);
                final spent = repository.expenseTotalForCategory(
                    budget.categoryId, budgetMonth);
                final ratio = effective > 0 ? spent / effective : 0.0;
                final isOver = ratio > 1.0;
                final color = isOver
                    ? const Color(0xFFE07B7B)
                    : ratio > 0.8
                        ? const Color(0xFFE8A838)
                        : const Color(0xFF6AAF8A);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              repository.categoryName(budget.categoryId),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${formatMoney(spent)} / ${formatMoney(effective)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: math.min(ratio, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
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

  int _monthCountForRange(ReportRangeType rangeType) {
    switch (rangeType) {
      case ReportRangeType.last3Months:
        return 3;
      case ReportRangeType.last6Months:
        return 6;
      case ReportRangeType.last12Months:
        return 12;
      case ReportRangeType.currentYear:
        return 12;
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
}

String _rangeLabel(ReportRangeType type) {
  return switch (type) {
    ReportRangeType.last3Months => '近 3 个月',
    ReportRangeType.last6Months => '近 6 个月',
    ReportRangeType.last12Months => '近 12 个月',
    ReportRangeType.currentYear => '本年度',
  };
}

String _measureLabel(ReportMeasureMode mode) {
  return switch (mode) {
    ReportMeasureMode.monthly => '单月',
    ReportMeasureMode.cumulative => '累计',
  };
}

String _dataFilterLabel(DataFilterMode mode) {
  return switch (mode) {
    DataFilterMode.actual => '已发生',
    DataFilterMode.all => '含预计',
  };
}

class _ReportControls extends StatelessWidget {
  const _ReportControls({
    required this.rangeType,
    required this.measureMode,
    required this.dataFilterMode,
    required this.monthCount,
    required this.onRangeChanged,
    required this.onMeasureChanged,
    required this.onDataFilterChanged,
  });

  final ReportRangeType rangeType;
  final ReportMeasureMode measureMode;
  final DataFilterMode dataFilterMode;
  final int monthCount;
  final ValueChanged<ReportRangeType> onRangeChanged;
  final ValueChanged<ReportMeasureMode> onMeasureChanged;
  final ValueChanged<DataFilterMode> onDataFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final rangeField = DropdownButtonFormField<ReportRangeType>(
          key: ValueKey(rangeType),
          initialValue: rangeType,
          decoration: const InputDecoration(
            labelText: '时间范围',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: ReportRangeType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(_rangeLabel(type)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onRangeChanged(value);
            }
          },
        );
        final measureToggle = SegmentedButton<ReportMeasureMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ReportMeasureMode.monthly, label: Text('单月')),
            ButtonSegment(
              value: ReportMeasureMode.cumulative,
              label: Text('累计'),
            ),
          ],
          selected: {measureMode},
          onSelectionChanged: (selection) {
            onMeasureChanged(selection.first);
          },
        );
        final dataToggle = SegmentedButton<DataFilterMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: DataFilterMode.actual, label: Text('已发生')),
            ButtonSegment(value: DataFilterMode.all, label: Text('含预计')),
          ],
          selected: {dataFilterMode},
          onSelectionChanged: (selection) {
            onDataFilterChanged(selection.first);
          },
        );
        final aiButton = SizedBox(
          height: 48,
          child: _AiAnalysisButton(
            includePlanned: dataFilterMode == DataFilterMode.all,
            monthCount: monthCount,
          ),
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rangeField,
              const SizedBox(height: 12),
              measureToggle,
              const SizedBox(height: 12),
              dataToggle,
              const SizedBox(height: 12),
              aiButton,
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: rangeField),
                const SizedBox(width: 12),
                Expanded(child: aiButton),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: measureToggle),
                const SizedBox(width: 12),
                Expanded(child: dataToggle),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReportCardGrid extends StatelessWidget {
  const _ReportCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

// ── KPI 卡片 ─────────────────────────────────────────────────
class _KpiCards extends StatelessWidget {
  const _KpiCards({
    required this.totalAssets,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.isCumulative,
  });

  final double totalAssets;
  final double monthlyIncome;
  final double monthlyExpense;
  final bool isCumulative;

  @override
  Widget build(BuildContext context) {
    final net = monthlyIncome - monthlyExpense;
    final prefix = isCumulative ? '累计' : '本月';
    final cards = [
      FinanceMetricCard(
        label: '净资产',
        value: formatMoney(totalAssets),
        color: const Color(0xFF5B9BD5),
        padding: const EdgeInsets.all(14),
        valueSize: 17,
      ),
      FinanceMetricCard(
        label: '$prefix收入',
        value: formatMoney(monthlyIncome),
        color: const Color(0xFF6AAF8A),
        padding: const EdgeInsets.all(14),
        valueSize: 17,
      ),
      FinanceMetricCard(
        label: '$prefix支出',
        value: formatMoney(monthlyExpense),
        color: const Color(0xFFE07B7B),
        padding: const EdgeInsets.all(14),
        valueSize: 17,
      ),
      FinanceMetricCard(
        label: '$prefix结余',
        value: formatMoney(net),
        color: net >= 0 ? const Color(0xFF6AAF8A) : const Color(0xFFE07B7B),
        padding: const EdgeInsets.all(14),
        valueSize: 17,
      ),
    ];

    return FinanceMetricGrid(
      gap: 10,
      minItemWidth: 168,
      maxColumns: 4,
      children: cards,
    );
  }
}

// ── 月度柱状图 (带 Y 轴) ──────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.summaries, required this.now});

  final List<MonthlySummary> summaries;
  final DateTime now;

  static const double _yAxisWidth = 36;
  static const double _chartHeight = 200;
  static const double _topPadding = 12;
  static const double _bottomLabelHeight = 22;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('暂无数据')));
    }

    final maxValue = summaries.fold<double>(
      0,
      (max, item) => math.max(max, math.max(item.income, item.expense)),
    );
    if (maxValue == 0) {
      return const SizedBox(
        height: _chartHeight,
        child: Center(child: Text('暂无数据')),
      );
    }

    final nowKey = monthKeyFromDate(DateTime(now.year, now.month));
    // Round up maxValue to a nice number for axis labels
    final niceMax = _niceMaxValue(maxValue);
    final axisLabels = _axisLabels(niceMax);

    return SizedBox(
      height: _chartHeight + _topPadding,
      child: Column(
        children: [
          // Legend
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6AAF8A),
                      borderRadius: BorderRadius.circular(2),
                    )),
                const SizedBox(width: 4),
                Text('收入',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(width: 16),
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07B7B),
                      borderRadius: BorderRadius.circular(2),
                    )),
                const SizedBox(width: 4),
                Text('支出',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: _yAxisWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: axisLabels.reversed.map((label) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          label,
                          style:
                              TextStyle(fontSize: 9, color: Colors.grey[500]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Vertical axis line
                Container(
                  width: 1,
                  color: Colors.grey[300],
                ),
                // Bars area
                Expanded(
                  child: Stack(
                    children: [
                      // Grid lines
                      ...axisLabels.asMap().entries.map((entry) {
                        final ratio = entry.key / (axisLabels.length - 1);
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: ratio * (_chartHeight - _bottomLabelHeight),
                          child: Container(
                            height:
                                entry.key == axisLabels.length - 1 ? 1 : 0.5,
                            color: entry.key == axisLabels.length - 1
                                ? Colors.grey[300]
                                : Colors.grey[100],
                          ),
                        );
                      }),
                      // Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: summaries.map((s) {
                          final isFuture = s.monthKey.compareTo(nowKey) > 0;
                          const barAreaHeight =
                              _chartHeight - _bottomLabelHeight;
                          final incomeHeight =
                              (s.income / niceMax) * barAreaHeight;
                          final expenseHeight =
                              (s.expense / niceMax) * barAreaHeight;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: incomeHeight,
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? const Color(0xFF6AAF8A)
                                                  .withValues(alpha: 0.3)
                                              : const Color(0xFF6AAF8A),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Container(
                                        width: 10,
                                        height: expenseHeight,
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? const Color(0xFFE07B7B)
                                                  .withValues(alpha: 0.3)
                                              : const Color(0xFFE07B7B),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: _bottomLabelHeight,
                                    child: Center(
                                      child: Text(
                                        monthLabel(s.monthKey),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isFuture
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _niceMaxValue(double value) {
    if (value <= 0) return 1;
    final magnitude =
        math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
    final normalized = value / magnitude;
    double niceNormalized;
    if (normalized <= 1.0) {
      niceNormalized = 1.0;
    } else if (normalized <= 2.0) {
      niceNormalized = 2.0;
    } else if (normalized <= 5.0) {
      niceNormalized = 5.0;
    } else {
      niceNormalized = 10.0;
    }
    return niceNormalized * magnitude;
  }

  List<String> _axisLabels(double maxValue) {
    const count = 5;
    return List.generate(count, (i) {
      final value = maxValue * i / (count - 1);
      return _formatAxisValue(value);
    });
  }

  String _formatAxisValue(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(value % 10000 == 0 ? 0 : 1)}万';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    } else if (value > 0) {
      return value.toStringAsFixed(0);
    }
    return '0';
  }
}

// ── 资产分布 (饼图) ──────────────────────────────────────────
class _AssetDistributionPieChart extends StatelessWidget {
  const _AssetDistributionPieChart({required this.repository});

  final FinanceRepository repository;

  static const _groupColors = <ReportGroup, Color>{
    ReportGroup.cash: Color(0xFF5B9BD5),
    ReportGroup.credit: Color(0xFFE07B7B),
    ReportGroup.investment: Color(0xFF6AAF8A),
    ReportGroup.retirement: Color(0xFFE8A838),
  };

  @override
  Widget build(BuildContext context) {
    final total = repository.totalAssets();
    if (total == 0) return const Text('暂无资产数据');

    final entries = <_AssetEntry>[];
    for (final group in ReportGroup.values) {
      final amount = repository.totalAssetsByGroup(group);
      if (amount != 0) {
        entries.add(_AssetEntry(
          label: _groupLabel(group),
          amount: amount,
          pct: (amount / total * 100),
          color: _groupColors[group]!,
        ));
      }
    }

    final pie = SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _PieChartPainter(entries: entries),
      ),
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(e.amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${e.pct.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            children: [
              Center(child: pie),
              const SizedBox(height: 14),
              legend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pie,
            const SizedBox(width: 20),
            Expanded(child: legend),
          ],
        );
      },
    );
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
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.entries});

  final List<_AssetEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -math.pi / 2; // Start from top
    for (final entry in entries) {
      final sweepAngle = (entry.pct / 100) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = entry.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _AssetEntry {
  final String label;
  final double amount;
  final double pct;
  final Color color;
  _AssetEntry(
      {required this.label,
      required this.amount,
      required this.pct,
      required this.color});
}

// ── 账户明细 ─────────────────────────────────────────────────
class _AccountDetails extends StatelessWidget {
  const _AccountDetails({required this.repository});

  final FinanceRepository repository;

  @override
  Widget build(BuildContext context) {
    final now = repository.currentMonthCutoffDate();
    final rows = <_AccountRow>[];
    for (final group in ReportGroup.values) {
      for (final acc in repository.accountsByGroup(group)) {
        final balance = repository.accountBalanceAtBase(acc.id, now);
        rows.add(_AccountRow(
          name: acc.name,
          typeLabel: _accountTypeLabel(acc.accountType),
          balance: balance,
        ));
      }
    }

    if (rows.isEmpty) {
      return const Text('暂无账户数据', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: rows.map((row) {
        final isNegative = row.balance < 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  row.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.typeLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
              Text(
                formatMoney(row.balance),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isNegative
                      ? const Color(0xFFE07B7B)
                      : const Color(0xFF6AAF8A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return '现金';
      case AccountType.bankSaving:
        return '储蓄';
      case AccountType.eWallet:
        return '电子钱包';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.moneyMarketFund:
        return '货币基金';
      case AccountType.pension:
        return '养老金';
      case AccountType.stock:
        return '股票';
      case AccountType.crypto:
        return '加密货币';
      case AccountType.trading:
        return '交易';
      case AccountType.fund:
        return '基金';
      case AccountType.other:
        return '其他';
    }
  }
}

class _AccountRow {
  final String name;
  final String typeLabel;
  final double balance;
  _AccountRow(
      {required this.name, required this.typeLabel, required this.balance});
}

// ── AI 分析 ─────────────────────────────────────────────────
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
      if (current.completed && current.summary != null) {
        ref.read(aiAnalysisProvider.notifier).dismissCompleted();
        _showCompletedDialog();
      }

      ref.listen<AiAnalysisState>(aiAnalysisProvider, (prev, next) {
        if (next.completed && next.summary != null) {
          ref.read(aiAnalysisProvider.notifier).dismissCompleted();
          _showCompletedDialog();
        }
        if (next.error != null && prev?.error == null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('AI 分析失败'),
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
        title: const Text('分析完成'),
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

    if (aiState.loading) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFF5B9BD5).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('AI 正在分析中...',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B8F7B))),
          ],
        ),
      );
    }

    if (aiState.summary == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF5B9BD5).withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('AI 分析报告',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(aiAnalysisProvider.notifier).state =
                    const AiAnalysisState(),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiState.summary!,
            style: const TextStyle(
                fontSize: 13, height: 1.6, color: Color(0xFF2D4A3E)),
          ),
        ],
      ),
    );
  }
}

/// AI 分析按钮
class _AiAnalysisButton extends ConsumerWidget {
  const _AiAnalysisButton(
      {required this.includePlanned, required this.monthCount});

  final bool includePlanned;
  final int monthCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiAnalysisProvider);

    return OutlinedButton.icon(
      onPressed: aiState.loading
          ? null
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(includePlanned
                      ? 'AI 正在分析全部数据（含预计），完成后会通知你'
                      : 'AI 正在分析已发生数据，完成后会通知你'),
                  duration: const Duration(seconds: 3),
                ),
              );
              ref.read(aiAnalysisProvider.notifier).runAnalysis(
                    includePlanned: includePlanned,
                    monthCount: monthCount,
                  );
            },
      icon: aiState.loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome_outlined, size: 18),
      label: Text(aiState.loading ? '分析中...' : 'AI 分析',
          style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
