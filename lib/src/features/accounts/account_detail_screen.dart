import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import '../shared/simple_charts.dart';
import 'asset_snapshot_form_dialog.dart';

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({
    super.key,
    required this.account,
    required this.repository,
    required this.onEditSnapshot,
    required this.onDeleteSnapshot,
  });

  final Account account;
  final FinanceRepository repository;
  final Future<FinanceRepository> Function(AssetSnapshot snapshot) onEditSnapshot;
  final Future<FinanceRepository> Function(String snapshotId) onDeleteSnapshot;

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late FinanceRepository _repository;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository;
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = _repository.snapshotsForAccount(widget.account.id);
    final latestSnapshot = snapshots.isEmpty ? null : snapshots.last;
    final latestFlow = latestSnapshot == null
        ? const InvestmentFlowSummary(contribution: 0, withdrawal: 0)
        : _repository.investmentFlowSummaryForAccount(
            widget.account.id,
            upToDate: latestSnapshot.snapshotDate,
          );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ScreenHeader(
                title: widget.account.name,
                subtitle: '${_groupLabel(widget.account.reportGroup)} · ${widget.account.currency}',
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '当前资产',
                child: latestSnapshot == null
                    ? const Text('还没有资产快照。')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            children: [
                              _MetricPill(
                                label: '总市值',
                                value: formatMoney(
                                  latestSnapshot.marketValue,
                                  currency: widget.account.currency,
                                ),
                              ),
                              _MetricPill(
                                label: '累计投入',
                                value: formatMoney(
                                  latestFlow.contribution,
                                  currency: widget.account.currency,
                                ),
                              ),
                              _MetricPill(
                                label: '累计取出',
                                value: formatMoney(
                                  latestFlow.withdrawal,
                                  currency: widget.account.currency,
                                ),
                              ),
                              _MetricPill(
                                label: '累计成本',
                                value: formatMoney(
                                  _repository.snapshotCostBasis(latestSnapshot),
                                  currency: widget.account.currency,
                                ),
                              ),
                              _MetricPill(
                                label: '现金余额',
                                value: formatMoney(
                                  latestSnapshot.cashBalance,
                                  currency: widget.account.currency,
                                ),
                              ),
                              _MetricPill(
                                label: '未实现盈亏',
                                value: '${formatMoney(_repository.snapshotUnrealizedPnl(latestSnapshot), currency: widget.account.currency)} '
                                    '(${(_repository.snapshotPnlRatio(latestSnapshot) * 100).toStringAsFixed(1)}%)',
                                accent: _repository.snapshotUnrealizedPnl(latestSnapshot) >= 0
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFB91C1C),
                              ),
                            ],
                          ),
                          if (snapshots.length > 1) ...[
                            const SizedBox(height: 16),
                            MultiLineChart(
                              series: _buildFlowSeries(snapshots),
                              amountBuilder: (value) => formatMoney(
                                value,
                                currency: widget.account.currency,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '快照记录',
                subtitle: '修改和删除会立即更新余额与图表。',
                child: snapshots.isEmpty
                    ? const Text('还没有资产快照。')
                    : Column(
                        children: snapshots.reversed
                            .map((snapshot) => _SnapshotRow(
                                  snapshot: snapshot,
                                  repository: _repository,
                                  currency: widget.account.currency,
                                  onEdit: () => _editSnapshot(snapshot),
                                  onDelete: () => _deleteSnapshot(snapshot),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        if (_isSaving)
          IgnorePointer(
            child: Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Future<void> _editSnapshot(AssetSnapshot snapshot) async {
    final result = await showDialog<AssetSnapshot>(
      context: context,
      builder: (_) => AssetSnapshotFormDialog(
        repository: _repository,
        initialSnapshot: snapshot,
      ),
    );
    if (!mounted || result == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final nextRepository = await widget.onEditSnapshot(result);
      if (!mounted) {
        return;
      }
      setState(() {
        _repository = nextRepository;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资产快照已保存')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteSnapshot(AssetSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除资产快照'),
            content: const Text('删除后会重新计算这个账户的当前余额。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted || !confirmed) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final nextRepository = await widget.onDeleteSnapshot(snapshot.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _repository = nextRepository;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资产快照已删除')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：$error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<ChartSeries> _buildFlowSeries(List<AssetSnapshot> snapshots) {
    final contributionPoints = <ChartPoint>[];
    final withdrawalPoints = <ChartPoint>[];
    final marketValuePoints = <ChartPoint>[];

    for (final snapshot in snapshots) {
      final summary = _repository.investmentFlowSummaryForAccount(
        snapshot.accountId,
        upToDate: snapshot.snapshotDate,
      );
      final label = '${snapshot.snapshotDate.month}/${snapshot.snapshotDate.day}';
      contributionPoints.add(
        ChartPoint(label: label, value: summary.contribution),
      );
      withdrawalPoints.add(
        ChartPoint(label: label, value: summary.withdrawal),
      );
      marketValuePoints.add(
        ChartPoint(label: label, value: snapshot.marketValue),
      );
    }

    return const [
      Color(0xFF0F766E),
      Color(0xFFB45309),
      Color(0xFF1D4ED8),
    ].asMap().entries.map((entry) {
      final index = entry.key;
      final color = entry.value;
      switch (index) {
        case 0:
          return ChartSeries(
            label: '累计投入',
            points: contributionPoints,
            color: color,
          );
        case 1:
          return ChartSeries(
            label: '累计取出',
            points: withdrawalPoints,
            color: color,
          );
        default:
          return ChartSeries(
            label: '总市值',
            points: marketValuePoints,
            color: color,
          );
      }
    }).toList();
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

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({
    required this.snapshot,
    required this.repository,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  final AssetSnapshot snapshot;
  final FinanceRepository repository;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final flow = repository.investmentFlowSummaryForAccount(
      snapshot.accountId,
      upToDate: snapshot.snapshotDate,
    );
    final pnl = repository.snapshotUnrealizedPnl(snapshot);
    final ratio = repository.snapshotPnlRatio(snapshot);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${snapshot.snapshotDate.year}-${snapshot.snapshotDate.month.toString().padLeft(2, '0')}-${snapshot.snapshotDate.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: '编辑',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: '删除',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text('总市值 ${formatMoney(snapshot.marketValue, currency: currency)}'),
              Text('累计投入 ${formatMoney(flow.contribution, currency: currency)}'),
              Text('累计取出 ${formatMoney(flow.withdrawal, currency: currency)}'),
              Text('累计成本 ${formatMoney(repository.snapshotCostBasis(snapshot), currency: currency)}'),
              Text('现金余额 ${formatMoney(snapshot.cashBalance, currency: currency)}'),
              Text(
                '未实现盈亏 ${formatMoney(pnl, currency: currency)} (${(ratio * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: pnl >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
