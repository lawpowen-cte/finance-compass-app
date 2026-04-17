import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
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
  });

  final FinanceRepository repository;
  final Future<void> Function(Account account) onAddAccount;
  final Future<void> Function(Account account) onEditAccount;
  final Future<bool> Function(String accountId) onDeleteAccount;
  final Future<void> Function(AssetSnapshot snapshot) onAddSnapshot;

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
                children: accounts.map((account) {
                  final breakdown = repository.expenseBreakdownForAccount(
                    account.id,
                    _currentMonthKey(),
                  );
                  final sortedEntries = breakdown.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topCategory = sortedEntries.isEmpty
                      ? '本月暂无支出'
                      : '${repository.categoryName(sortedEntries.first.key)} ${formatMoney(sortedEntries.first.value)}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text('${_accountTypeLabel(account.accountType)} | $topCategory'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(formatMoney(account.currentBalance, currency: account.currency)),
                        PopupMenuButton<String>(
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
        return '储蓄户口';
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
        return '交易户口';
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
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
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
