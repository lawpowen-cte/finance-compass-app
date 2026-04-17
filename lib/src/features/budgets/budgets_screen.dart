import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/budget.dart';
import '../../core/utils/currency_formatter.dart';
import '../shared/screen_header.dart';
import 'budget_form_dialog.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({
    super.key,
    required this.repository,
    required this.onAddBudget,
    required this.onDeleteBudget,
  });

  final FinanceRepository repository;
  final Future<void> Function(Budget budget) onAddBudget;
  final Future<void> Function(String budgetId) onDeleteBudget;

  @override
  Widget build(BuildContext context) {
    final budgets = repository.reusableBudgets();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '预算',
          actions: [
            IconButton.filled(
              onPressed: () => _showAddBudget(context),
              icon: const Icon(Icons.add),
              tooltip: '新增预算',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (budgets.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: const Text('预算规则'),
              subtitle: const Text('每个类别只设置一次，后续每月复用'),
              trailing: Text(formatMoney(repository.totalBudgetAmount())),
            ),
          ),
        ...budgets.map((budget) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(repository.categoryName(budget.categoryId)),
              subtitle: Text(
                '设立于 ${budget.monthKey} · 阈值 ${(budget.alertThreshold * 100).round()}% · ${budget.rolloverEnabled ? '已启用结转' : '未结转'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatMoney(budget.amount)),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showEditBudget(context, budget);
                      }
                      if (value == 'delete') {
                        await onDeleteBudget(budget.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAddBudget(BuildContext context) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetFormDialog(repository: repository),
    );
    if (result != null) {
      await onAddBudget(result);
    }
  }

  Future<void> _showEditBudget(BuildContext context, Budget budget) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetFormDialog(
        repository: repository,
        initialBudget: budget,
      ),
    );
    if (result != null) {
      await onAddBudget(result);
    }
  }
}
