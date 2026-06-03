import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

enum ReportRangeType { last3Months, last6Months, last12Months, currentYear }
enum ReportMeasureMode { monthly, cumulative }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
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

    final budgetMonth = currentMonthKey;
    final activeBudgets = repository.activeBudgetsForMonth(budgetMonth);
    final goalSummaries = repository.assetGoalSummaries();

    // 本月实际数据
    final actualIncome = repository.totalIncomeForMonth(currentMonthKey);
    final actualExpense = repository.totalExpenseForMonth(currentMonthKey);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '报表',
          actions: [
            DropdownButton<ReportRangeType>(
              value: rangeType,
              items: const [
                DropdownMenuItem(value: ReportRangeType.last3Months, child: Text('近 3 个月')),
                DropdownMenuItem(value: ReportRangeType.last6Months, child: Text('近 6 个月')),
                DropdownMenuItem(value: ReportRangeType.last12Months, child: Text('近 12 个月')),
                DropdownMenuItem(value: ReportRangeType.currentYear, child: Text('本年度')),
              ],
              onChanged: (value) => setState(() => rangeType = value!),
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
            const SizedBox(width: 12),
            Expanded(child: _AiAnalysisButton()),
          ],
        ),
        _AiResultDisplay(),
        const SizedBox(height: 16),

        // ── KPI 卡片 ──
        _KpiCards(
          totalAssets: repository.totalAssets(),
          monthlyIncome: actualIncome,
          monthlyExpense: actualExpense,
        ),
        const SizedBox(height: 16),

        // ── 目标进度条 ──
        if (goalSummaries.isNotEmpty) ...[
          SectionCard(
            title: '🎯 资产目标',
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
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${formatMoney(g.currentAssets)} / ${formatMoney(g.goal.targetAmount)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color),
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
          title: measureMode == ReportMeasureMode.monthly ? '📊 收支趋势' : '📊 累计趋势',
          subtitle: rangeType == ReportRangeType.currentYear ? '未来月份浅色标记' : null,
          child: _MonthlyBarChart(
            summaries: displaySummaries,
            now: now,
          ),
        ),
        const SizedBox(height: 16),

        // ── 资产分布 ──
        SectionCard(
          title: '💰 资产分布',
          child: _AssetDistribution(repository: repository),
        ),
        const SizedBox(height: 16),

        // ── 预算状态 ──
        SectionCard(
          title: '📋 预算执行',
          subtitle: monthLabel(budgetMonth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeBudgets.isEmpty) const Text('暂无预算数据', style: TextStyle(color: Colors.grey)),
              ...activeBudgets.map((budget) {
                final effective = repository.effectiveBudgetForMonth(budget, budgetMonth);
                final spent = repository.expenseTotalForCategory(budget.categoryId, budgetMonth);
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${formatMoney(spent)} / ${formatMoney(effective)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

// ── KPI 卡片 ─────────────────────────────────────────────────
class _KpiCards extends StatelessWidget {
  const _KpiCards({
    required this.totalAssets,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  final double totalAssets;
  final double monthlyIncome;
  final double monthlyExpense;

  @override
  Widget build(BuildContext context) {
    final net = monthlyIncome - monthlyExpense;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _KpiCard(label: '总资产', value: formatMoney(totalAssets), color: const Color(0xFF5B9BD5)),
        _KpiCard(label: '本月收入', value: formatMoney(monthlyIncome), color: const Color(0xFF6AAF8A)),
        _KpiCard(label: '本月支出', value: formatMoney(monthlyExpense), color: const Color(0xFFE07B7B)),
        _KpiCard(label: '本月结余', value: formatMoney(net), color: net >= 0 ? const Color(0xFF6AAF8A) : const Color(0xFFE07B7B)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── 月度柱状图 ──────────────────────────────────────────────
class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.summaries, required this.now});

  final List<MonthlySummary> summaries;
  final DateTime now;

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
      return const SizedBox(height: 120, child: Center(child: Text('暂无数据')));
    }

    final nowKey = monthKeyFromDate(DateTime(now.year, now.month));

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: summaries.map((s) {
          final isFuture = s.monthKey.compareTo(nowKey) > 0;
          final incomeHeight = (s.income / maxValue) * 160;
          final expenseHeight = (s.expense / maxValue) * 160;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 柱子
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: incomeHeight,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? const Color(0xFF6AAF8A).withValues(alpha: 0.3)
                              : const Color(0xFF6AAF8A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Container(
                        width: 10,
                        height: expenseHeight,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? const Color(0xFFE07B7B).withValues(alpha: 0.3)
                              : const Color(0xFFE07B7B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 月份标签
                  Text(
                    monthLabel(s.monthKey),
                    style: TextStyle(
                      fontSize: 9,
                      color: isFuture ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 资产分布 ────────────────────────────────────────────────
class _AssetDistribution extends StatelessWidget {
  const _AssetDistribution({required this.repository});

  final FinanceRepository repository;

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
        ));
      }
    }

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(e.label, style: const TextStyle(fontSize: 13)),
              ),
              Text(formatMoney(e.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text(
                '${e.pct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }).toList(),
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

class _AssetEntry {
  final String label;
  final double amount;
  final double pct;
  _AssetEntry({required this.label, required this.amount, required this.pct});
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

    if (aiState.loading) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5B9BD5).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('🤖 AI 正在分析中...', style: TextStyle(fontSize: 13, color: Color(0xFF6B8F7B))),
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
        border: Border.all(color: const Color(0xFF5B9BD5).withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖 AI 分析报告', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(aiAnalysisProvider.notifier).state = const AiAnalysisState(),
                child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aiState.summary!,
            style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF2D4A3E)),
          ),
        ],
      ),
    );
  }
}

/// AI 分析按钮
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
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome_outlined, size: 18),
      label: Text(aiState.loading ? '分析中...' : 'AI 分析', style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
