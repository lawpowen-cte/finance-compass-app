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
          title: 'Accounts',
          actions: [
            IconButton.filledTonal(
              onPressed: () => _showAddAccount(context),
              icon: const Icon(Icons.add_card),
              tooltip: 'Add account',
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _showAddSnapshot(context),
              icon: const Icon(Icons.show_chart),
              tooltip: 'Add asset snapshot',
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...groups.map((group) {
          final accounts = repository.accountsByGroup(group);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              title: group.name,
              child: Column(
                children: accounts.map((account) {
                  final breakdown = repository.expenseBreakdownForAccount(
                    account.id,
                    _currentMonthKey(),
                  );
                  final sortedEntries = breakdown.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final topCategory = sortedEntries.isEmpty
                      ? 'No expense records this month'
                      : '${repository.categoryName(sortedEntries.first.key)} '
                          '${formatMoney(sortedEntries.first.value)}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(account.name),
                    subtitle: Text('${account.accountType.name} | $topCategory'),
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
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
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
          deleted
              ? 'Deleted ${account.name}.'
              : '${account.name} has linked transactions or asset snapshots and cannot be deleted.',
        ),
      ),
    );
  }

}
