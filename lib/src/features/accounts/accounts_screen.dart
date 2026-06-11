import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/account.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/providers/mutations/account_mutations.dart';
import '../../core/providers/mutations/asset_mutations.dart';

import '../../core/utils/currency_formatter.dart';
import '../shared/finance_action_menu_button.dart';
import '../shared/finance_status_chip.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import '../shared/simple_charts.dart';
import 'account_detail_screen.dart';
import 'account_form_dialog.dart';
import 'asset_snapshot_form_dialog.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({
    super.key,
    required this.repository,
  });

  final FinanceRepository repository;

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String? selectedCutoffMonth = _currentMonthKey();
  final Set<String> _collapsedAccounts = {};
  final Set<String> _expandedGoalIds = {};

  @override
  void initState() {
    super.initState();
    _loadCollapsedAccounts();
  }

  Future<void> _loadCollapsedAccounts() async {
    final raw = await DatabaseProvider.instance.getMetaValue('collapsed_accounts');
    if (raw != null && mounted) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _collapsedAccounts.addAll(decoded.cast<String>());
        });
      } catch (_) {
        // ignore parse errors
      }
    }
  }

  Future<void> _toggleAccountCollapse(String accountId) async {
    setState(() {
      if (_collapsedAccounts.contains(accountId)) {
        _collapsedAccounts.remove(accountId);
      } else {
        _collapsedAccounts.add(accountId);
      }
    });
    await DatabaseProvider.instance.setMetaValue(
      'collapsed_accounts',
      jsonEncode(_collapsedAccounts.toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const groups = ReportGroup.values;
    final repository = widget.repository;
    final monthKeys = <String>{
      _currentMonthKey(),
      ...repository.transactions.map((item) => _monthKey(item.transactionDate)),
      ...repository.snapshots.map((item) => _monthKey(item.snapshotDate)),
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    final effectiveCutoffMonth = monthKeys.contains(selectedCutoffMonth)
        ? selectedCutoffMonth!
        : _currentMonthKey();
    final displayCutoff = _endOfMonth(effectiveCutoffMonth);
    final goalSummaries =
        repository.assetGoalSummaries(cutoffDate: displayCutoff);
    final goalHistory = repository.totalAssetHistory(cutoffDate: displayCutoff);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '账户',
          actions: [
            IconButton.filledTonal(
              onPressed: () => _showGoalDialog(context),
              icon: const Icon(Icons.flag_outlined),
              tooltip: '资产目标',
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _showAddAccount(context),
              icon: const Icon(Icons.add_card),
              tooltip: '新增账户',
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _showAddSnapshot(context),
              icon: const Icon(Icons.show_chart),
              tooltip: '新增资产快照',
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '统计截止',
          child: DropdownButtonFormField<String>(
            value: effectiveCutoffMonth,
            decoration: const InputDecoration(
              labelText: '截至月份',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: monthKeys
                .map(
                  (monthKey) => DropdownMenuItem<String>(
                    value: monthKey,
                    child: Text(monthKey),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => selectedCutoffMonth = value);
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryChip(
              label: '净资产',
              value: formatMoney(
                repository.displayTotalAssets(cutoffDate: displayCutoff),
              ),
            ),
            _SummaryChip(
              label: '总资产',
              value: formatMoney(
                repository.displayTotalAssets(
                  includeCredit: false,
                  cutoffDate: displayCutoff,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: '资产目标',
          subtitle:
              goalSummaries.isEmpty ? '设定目标后会自动记录首次达成日期。' : '支持同时追踪多个净资产目标。',
          child: goalSummaries.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _showGoalDialog(context),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('新增资产目标'),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showGoalDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('新增目标'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (goalHistory.isNotEmpty) ...[
                      SimpleLineChart(
                        points: goalHistory
                            .map(
                              (point) => ChartPoint(
                                label: point.label.substring(2),
                                value: point.totalAssets,
                              ),
                            )
                            .toList(),
                        amountBuilder: formatMoneyValue,
                      ),
                      const SizedBox(height: 12),
                    ],
                    ...goalSummaries.map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCard(
                          summary: summary,
                          isExpanded:
                              _expandedGoalIds.contains(summary.goal.id),
                          onToggleExpanded: summary.isReached
                              ? null
                              : () => setState(() {
                                    if (!_expandedGoalIds
                                        .remove(summary.goal.id)) {
                                      _expandedGoalIds.add(summary.goal.id);
                                    }
                                  }),
                          onEdit: () => _showGoalDialog(
                            context,
                            initialGoal: summary.goal,
                          ),
                          onDelete: () => _deleteGoal(context, summary.goal),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ...groups.map((group) {
          final accounts = repository.accountsByGroup(group);
          final groupTotal = repository.displayTotalAssetsByGroup(
            group,
            cutoffDate: displayCutoff,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              title: _groupLabel(group),
              subtitle: '总额 ${formatMoney(groupTotal)}',
              child: Column(
                children: accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  final isCollapsed = _collapsedAccounts.contains(account.id);
                  final breakdown = repository.expenseBreakdownForAccount(
                    account.id,
                    _currentMonthKey(),
                  );
                  final sortedEntries = breakdown.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topCategory = sortedEntries.isEmpty
                      ? '本月暂无支出'
                      : '${repository.categoryName(sortedEntries.first.key)} '
                          '${formatMoney(sortedEntries.first.value, currency: account.currency)}';
                  final latestSnapshot =
                      repository.latestSnapshotForAccountUpTo(
                    account.id,
                    displayCutoff,
                  );
                  final displayedMarketValue = repository.accountBalanceAt(
                    account.id,
                    displayCutoff,
                  );
                  final displayedCostBasis = repository.costBasisForAccount(
                    account.id,
                    upToDate: displayCutoff,
                  );
                  final displayedCashBalance = repository.cashBalanceForAccount(
                    account.id,
                    upToDate: displayCutoff,
                  );
                  final displayedFlow =
                      repository.investmentFlowSummaryForAccount(
                    account.id,
                    upToDate: displayCutoff,
                  );
                  final reconciledMonth = repository.reconciledMonthForAccount(
                    account.id,
                  );
                  final isReconciledForCutoff =
                      repository.isAccountReconciledForMonth(
                    account.id,
                    effectiveCutoffMonth,
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountDetailScreen(
                          account: account,
                          repository: repository,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _toggleAccountCollapse(account.id),
                                child: Icon(
                                  isCollapsed
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    if (!isCollapsed) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_accountTypeLabel(account.accountType)} · $topCategory',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      FinanceStatusChip(
                                        icon: isReconciledForCutoff
                                            ? Icons.verified_outlined
                                            : Icons.pending_actions_outlined,
                                        label: reconciledMonth == null
                                            ? '未对账'
                                            : '已对账到 $reconciledMonth',
                                        color: isReconciledForCutoff
                                            ? const Color(0xFF047857)
                                            : const Color(0xFFB45309),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatMoney(
                                      displayedMarketValue,
                                      currency: account.currency,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (!isCollapsed) ...[
                                    Text(
                                      repository.conversionHintForAmount(
                                        displayedMarketValue,
                                        account.currency,
                                      ),
                                      style:
                                          Theme.of(context).textTheme.labelSmall,
                                    ),
                                    FinanceActionMenuButton<String>(
                                      tooltip: '账户操作',
                                      items: const [
                                        FinanceActionMenuItem(
                                          value: 'trace',
                                          label: '数字追溯',
                                          icon: Icons.manage_search_outlined,
                                        ),
                                        FinanceActionMenuItem(
                                          value: 'reconcile',
                                          label: '标记已对账',
                                          icon: Icons.verified_outlined,
                                        ),
                                        FinanceActionMenuItem(
                                          value: 'edit',
                                          label: '编辑',
                                          icon: Icons.edit_outlined,
                                          dividerBefore: true,
                                        ),
                                        FinanceActionMenuItem(
                                          value: 'delete',
                                          label: '删除',
                                          icon: Icons.delete_outline,
                                          destructive: true,
                                        ),
                                      ],
                                      onSelected: (value) => _handleAccountAction(
                                        context,
                                        value,
                                        account,
                                        effectiveCutoffMonth,
                                        displayCutoff,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (!isCollapsed && latestSnapshot != null) ...[
                            const SizedBox(height: 12),
                            _SnapshotSummary(
                              snapshot: latestSnapshot,
                              currency: account.currency,
                              displayedMarketValue: displayedMarketValue,
                              displayedCostBasis: displayedCostBasis,
                              displayedCashBalance: displayedCashBalance,
                              flowSummary: displayedFlow,
                              trendValues: repository
                                  .snapshotsForAccountUpTo(
                                      account.id, displayCutoff)
                                  .map(
                                    (item) => repository.accountBalanceAt(
                                      account.id,
                                      item.snapshotDate,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (index != accounts.length - 1) ...[
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.55),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showGoalDialog(
    BuildContext context, {
    AssetGoal? initialGoal,
  }) async {
    final nameController = TextEditingController(text: initialGoal?.name ?? '');
    final amountController = TextEditingController(
      text: initialGoal == null
          ? ''
          : initialGoal.targetAmount.toStringAsFixed(2),
    );
    final result = await showDialog<_GoalDraft?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialGoal == null ? '新增资产目标' : '编辑资产目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '目标名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '目标金额',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                _GoalDraft(
                  name: nameController.text.trim(),
                  amount: double.tryParse(amountController.text.trim()),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (!context.mounted || result == null) {
      return;
    }
    if (result.name.isEmpty || result.amount == null || result.amount! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入目标名称和有效金额')),
      );
      return;
    }
    if (initialGoal == null) {
      await ref.read(accountMutationsProvider.notifier).addAssetGoal(
            name: result.name,
            amount: result.amount!,
          );
      return;
    }
    await ref.read(accountMutationsProvider.notifier).updateAssetGoal(
          initialGoal.copyWith(
            name: result.name,
            targetAmount: result.amount!,
          ),
        );
  }

  Future<void> _deleteGoal(BuildContext context, AssetGoal goal) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除资产目标'),
            content: Text('确定删除"${goal.name}"吗？'),
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
    if (!context.mounted || !confirmed) {
      return;
    }
    await ref.read(accountMutationsProvider.notifier).deleteAssetGoal(goal.id);
  }

  Future<void> _showAddAccount(BuildContext context) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (_) => const AccountFormDialog(),
    );
    if (!context.mounted || result == null) {
      return;
    }
    await ref.read(accountMutationsProvider.notifier).addAccount(result);
  }

  Future<void> _showAddSnapshot(BuildContext context) async {
    final result = await showDialog<AssetSnapshot>(
      context: context,
      builder: (_) => AssetSnapshotFormDialog(repository: widget.repository),
    );
    if (!context.mounted || result == null) {
      return;
    }
    await ref.read(assetMutationsProvider.notifier).addSnapshot(result);
  }

  Future<void> _showEditAccount(BuildContext context, Account account) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (_) => AccountFormDialog(initialAccount: account),
    );
    if (!context.mounted || result == null) {
      return;
    }
    await ref.read(accountMutationsProvider.notifier).updateAccount(result);
  }

  Future<void> _attemptDeleteAccount(
      BuildContext context, Account account) async {
    final deleted = await ref
        .read(accountMutationsProvider.notifier)
        .deleteAccount(account.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? '已删除 ${account.name}' : '${account.name} 有关联数据，不能删除',
        ),
      ),
    );
  }

  Future<void> _handleAccountAction(
    BuildContext context,
    String value,
    Account account,
    String cutoffMonth,
    DateTime cutoffDate,
  ) async {
    if (value == 'trace') {
      _showBalanceTrace(context, account, cutoffDate);
      return;
    }
    if (value == 'reconcile') {
      await ref
          .read(accountMutationsProvider.notifier)
          .setAccountReconciledMonth(account.id, cutoffMonth);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${account.name} 已对账到 $cutoffMonth')),
      );
      return;
    }
    if (value == 'edit') {
      await _showEditAccount(context, account);
      return;
    }
    if (value == 'delete') {
      await _attemptDeleteAccount(context, account);
    }
  }

  void _showBalanceTrace(
    BuildContext context,
    Account account,
    DateTime cutoffDate,
  ) {
    final trace = widget.repository.accountBalanceTrace(account.id, cutoffDate);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account.name} 数字追溯'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TraceSummaryRow(
                  label: '截止日',
                  value: _dateLabel(trace.cutoffDate),
                ),
                _TraceSummaryRow(
                  label: trace.sourceLabel,
                  value: formatMoney(
                    trace.sourceAmount,
                    currency: account.currency,
                  ),
                ),
                _TraceSummaryRow(
                  label: '追溯余额',
                  value: formatMoney(
                    trace.endingBalance,
                    currency: account.currency,
                  ),
                  emphasize: true,
                ),
                const SizedBox(height: 12),
                Text(
                  '说明：系统以当前余额或最近资产快照为锚点，扣回截止日之后已经记录的交易，得到该时间点余额。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 8),
                if (trace.entries.isEmpty)
                  Text(
                    '没有截止日之后影响此账户的交易。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...trace.entries.map(
                    (entry) => _TraceEntryTile(
                      entry: entry,
                      currency: account.currency,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _endOfMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
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

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return '现金';
      case AccountType.bankSaving:
        return '储蓄账户';
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
        return '交易账户';
      case AccountType.fund:
        return '基金';
      case AccountType.other:
        return '其他';
    }
  }
}

class _GoalStatusLine extends StatelessWidget {
  const _GoalStatusLine({required this.summary});

  final AssetGoalProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.isReached) {
      final date = summary.reachedAt;
      final dateStr = date == null ? '' : '${date.year}年${date.month}月';
      return Text(
        '🎉 已达成 $dateStr',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF15803D),
              fontWeight: FontWeight.w600,
            ),
      );
    }

    // 未达成：计算剩余金额和预估月数
    final remaining = summary.goal.targetAmount - summary.currentAssets;
    final history = summary.history;
    String estimate = '';
    if (history.length >= 2) {
      final recent =
          history.length > 3 ? history.sublist(history.length - 3) : history;
      final firstVal = recent.first.totalAssets;
      final lastVal = recent.last.totalAssets;
      final months = recent.length - 1;
      if (months > 0 && lastVal > firstVal) {
        final monthlyGrowth = (lastVal - firstVal) / months;
        if (monthlyGrowth > 0) {
          final monthsNeeded = (remaining / monthlyGrowth).ceil();
          if (monthsNeeded <= 120) {
            estimate = ' · 预计${monthsNeeded > 0 ? monthsNeeded : 1}个月后达成';
          }
        }
      }
    }

    return Text(
      '还差 ${formatMoney(remaining)}$estimate',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.summary,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onDelete,
  });

  final AssetGoalProgressSummary summary;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.74),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.goal.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    _GoalStatusLine(summary: summary),
                  ],
                ),
              ),
              if (!summary.isReached)
                IconButton(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  tooltip: isExpanded ? '收起' : '展开',
                ),
              FinanceActionMenuButton<String>(
                tooltip: '目标操作',
                items: const [
                  FinanceActionMenuItem(
                    value: 'edit',
                    label: '编辑',
                    icon: Icons.edit_outlined,
                  ),
                  FinanceActionMenuItem(
                    value: 'delete',
                    label: '删除',
                    icon: Icons.delete_outline,
                    destructive: true,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
          if (!summary.isReached)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricChip(
                        label: '目标金额',
                        value: formatMoney(summary.goal.targetAmount),
                      ),
                      _MetricChip(
                        label: '当前净资产',
                        value: formatMoney(summary.currentAssets),
                      ),
                      _MetricChip(
                        label: '达成进度',
                        value:
                            '${(summary.progressRatio * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: summary.progressRatio.clamp(0, 1),
                    ),
                  ),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
        ],
      ),
    );
  }
}

class _GoalDraft {
  const _GoalDraft({
    required this.name,
    required this.amount,
  });

  final String name;
  final double? amount;
}

class _TraceSummaryRow extends StatelessWidget {
  const _TraceSummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _TraceEntryTile extends StatelessWidget {
  const _TraceEntryTile({
    required this.entry,
    required this.currency,
  });

  final AccountBalanceTraceEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final deltaColor =
        entry.delta >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final date =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMoney(entry.delta, currency: currency),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: deltaColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(entry.subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(date, style: Theme.of(context).textTheme.labelSmall),
              Text(
                '调整后 ${formatMoney(entry.runningBalance, currency: currency)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotSummary extends StatelessWidget {
  const _SnapshotSummary({
    required this.snapshot,
    required this.currency,
    required this.flowSummary,
    required this.displayedMarketValue,
    required this.displayedCostBasis,
    required this.displayedCashBalance,
    required this.trendValues,
  });

  final AssetSnapshot snapshot;
  final String currency;
  final InvestmentFlowSummary flowSummary;
  final double displayedMarketValue;
  final double displayedCostBasis;
  final double displayedCashBalance;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final remainingCostBasis = (displayedCostBasis - flowSummary.withdrawal)
        .clamp(0, double.infinity)
        .toDouble();
    final pnl = displayedMarketValue - remainingCostBasis;
    final ratio = remainingCostBasis == 0 ? 0.0 : pnl / remainingCostBasis;
    final pnlColor =
        pnl >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新快照 ${snapshot.snapshotDate.year}-${snapshot.snapshotDate.month.toString().padLeft(2, '0')}-${snapshot.snapshotDate.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text(
                  '总市值 ${formatMoney(displayedMarketValue, currency: currency)}'),
              Text(
                  '累计投入 ${formatMoney(flowSummary.contribution, currency: currency)}'),
              Text(
                  '累计取出 ${formatMoney(flowSummary.withdrawal, currency: currency)}'),
              Text(
                  '累计成本 ${formatMoney(displayedCostBasis, currency: currency)}'),
              Text(
                  '现金余额 ${formatMoney(displayedCashBalance, currency: currency)}'),
              Text(
                '未实现盈亏 ${formatMoney(pnl, currency: currency)} (${(ratio * 100).toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: pnlColor,
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
