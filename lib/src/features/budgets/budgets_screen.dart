import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/budget.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
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
    final currentMonth = monthKeyFromDate(DateTime.now());
    final totalBudget = repository.totalEffectiveBudgetForMonth(currentMonth);
    final totalSpent = repository.totalBudgetExpenseForMonth(currentMonth);

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
        Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: '本月总预算',
                    value: formatMoney(totalBudget),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: '本月已使用',
                    value: formatMoney(totalSpent),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (budgets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('还没有预算，先新增一笔。'),
            ),
          ),
        ...budgets.map(
          (budget) => _BudgetTile(
            budget: budget,
            repository: repository,
            currentMonth: currentMonth,
            onEdit: () => _showEditBudget(context, budget),
            onDelete: () => onDeleteBudget(budget.id),
          ),
        ),
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

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.repository,
    required this.currentMonth,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final FinanceRepository repository;
  final String currentMonth;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = budget.amount;
    final effectiveBudget = repository.effectiveBudgetForMonth(budget, currentMonth);
    final spent = repository.expenseTotalForCategory(budget.categoryId, currentMonth);
    final monthlyBalance = effectiveBudget - spent;
    final usage = effectiveBudget <= 0 ? 0.0 : (spent / effectiveBudget).clamp(0.0, 1.0);
    final percent = (usage * 100).round();
    final rolloverMark = budget.rolloverEnabled ? '↺' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          repository.categoryName(budget.categoryId),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (rolloverMark.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          rolloverMark,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await onEdit();
                    }
                    if (value == 'delete') {
                      await onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('编辑')),
                    PopupMenuItem(value: 'delete', child: Text('删除')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: '预算',
                    value: formatMoney(monthlyBudget),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: '本月余额',
                    value: formatMoney(monthlyBalance),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: '已使用',
                    value: formatMoney(spent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: usage,
                backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
