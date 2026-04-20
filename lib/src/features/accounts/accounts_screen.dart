import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import '../shared/simple_charts.dart';
import 'account_detail_screen.dart';
import 'account_form_dialog.dart';
import 'asset_snapshot_form_dialog.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({
    super.key,
    required this.repository,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onDeleteAccount,
    required this.onAddSnapshot,
    required this.onEditSnapshot,
    required this.onDeleteSnapshot,
  });

  final FinanceRepository repository;
  final Future<void> Function(Account account) onAddAccount;
  final Future<void> Function(Account account) onEditAccount;
  final Future<bool> Function(String accountId) onDeleteAccount;
  final Future<void> Function(AssetSnapshot snapshot) onAddSnapshot;
  final Future<FinanceRepository> Function(AssetSnapshot snapshot) onEditSnapshot;
  final Future<FinanceRepository> Function(String snapshotId) onDeleteSnapshot;

  @override
  Widget build(BuildContext context) {
    const groups = ReportGroup.values;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '账户',
          actions: [
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryChip(
              label: '总资产',
              value: formatMoney(repository.totalAssets()),
            ),
            _SummaryChip(
              label: '净资产',
              value: formatMoney(repository.totalAssets(includeCredit: false)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...groups.map((group) {
          final accounts = repository.accountsByGroup(group);
          final groupTotal = repository.totalAssetsByGroup(group);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              title: _groupLabel(group),
              subtitle: '总额 ${formatMoney(groupTotal)}',
              child: Column(
                children: accounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  final breakdown = repository.expenseBreakdownForAccount(
                    account.id,
                    _currentMonthKey(),
                  );
                  final sortedEntries = breakdown.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topCategory = sortedEntries.isEmpty
                      ? '本月暂无支出'
                      : '${repository.categoryName(sortedEntries.first.key)} ${formatMoney(sortedEntries.first.value)}';
                  final latestSnapshot = repository.latestSnapshotForAccount(account.id);
                  final latestFlow = latestSnapshot == null
                      ? const InvestmentFlowSummary(contribution: 0, withdrawal: 0)
                      : repository.investmentFlowSummaryForAccount(
                          account.id,
                          upToDate: latestSnapshot.snapshotDate,
                        );

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountDetailScreen(
                          account: account,
                          repository: repository,
                          onEditSnapshot: onEditSnapshot,
                          onDeleteSnapshot: onDeleteSnapshot,
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      account.name,
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_accountTypeLabel(account.accountType)} · $topCategory',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatMoney(account.currentBalance, currency: account.currency),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditAccount(context, account);
                                      }
                                      if (value == 'delete') {
                                        _attemptDeleteAccount(context, account);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                                      PopupMenuItem(value: 'delete', child: Text('删除')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (latestSnapshot != null) ...[
                            const SizedBox(height: 12),
                            _SnapshotSummary(
                              snapshot: latestSnapshot,
                              repository: repository,
                              currency: account.currency,
                              flowSummary: latestFlow,
                              trendValues: repository
                                  .snapshotsForAccount(account.id)
                                  .map((item) => item.marketValue)
                                  .toList(),
                            ),
                          ],
                          if (index != accounts.length - 1) ...[
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55),
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

  String _currentMonthKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
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

  Future<void> _showAddAccount(BuildContext context) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (_) => const AccountFormDialog(),
    );
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      await onAddAccount(result);
    }
  }

  Future<void> _showAddSnapshot(BuildContext context) async {
    final result = await showDialog<AssetSnapshot>(
      context: context,
      builder: (_) => AssetSnapshotFormDialog(repository: repository),
    );
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      await onAddSnapshot(result);
    }
  }

  Future<void> _showEditAccount(BuildContext context, Account account) async {
    final result = await showDialog<Account>(
      context: context,
      builder: (_) => AccountFormDialog(initialAccount: account),
    );
    if (!context.mounted) {
      return;
    }
    if (result != null) {
      await onEditAccount(result);
    }
  }

  Future<void> _attemptDeleteAccount(BuildContext context, Account account) async {
    final deleted = await onDeleteAccount(account.id);
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
}

class _SnapshotSummary extends StatelessWidget {
  const _SnapshotSummary({
    required this.snapshot,
    required this.repository,
    required this.currency,
    required this.flowSummary,
    required this.trendValues,
  });

  final AssetSnapshot snapshot;
  final FinanceRepository repository;
  final String currency;
  final InvestmentFlowSummary flowSummary;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final pnl = repository.snapshotUnrealizedPnl(snapshot);
    final ratio = repository.snapshotPnlRatio(snapshot);
    final pnlColor = pnl >= 0 ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

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
              Text('总市值 ${formatMoney(snapshot.marketValue, currency: currency)}'),
              Text('累计投入 ${formatMoney(flowSummary.contribution, currency: currency)}'),
              Text('累计取出 ${formatMoney(flowSummary.withdrawal, currency: currency)}'),
              Text('净投入 ${formatMoney(flowSummary.netContribution, currency: currency)}'),
              Text('现金余额 ${formatMoney(snapshot.cashBalance, currency: currency)}'),
              Text(
                '未实现盈亏 ${formatMoney(pnl, currency: currency)} (${(ratio * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: pnlColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (trendValues.length > 1) ...[
            const SizedBox(height: 10),
            MiniSparkline(
              points: trendValues,
              color: pnl >= 0 ? const Color(0xFF15803D) : const Color(0xFF0F766E),
            ),
          ],
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
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).cardColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
