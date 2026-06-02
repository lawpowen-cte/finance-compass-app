import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/budget.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../shared/screen_header.dart';
import 'budget_form_dialog.dart';

class BudgetsScreen extends StatefulWidget {
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
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late String _selectedMonth;
  final _expandedBudgetIds = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedMonth = monthKeyFromDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final budgets = repository.reusableBudgets();
    final monthOptions = _buildMonthOptions();
    if (!monthOptions.contains(_selectedMonth)) {
      _selectedMonth = monthOptions.first;
    }

    final totalBudget = repository.totalEffectiveBudgetForMonth(_selectedMonth);
    final totalSpent = repository.totalBudgetExpenseForMonth(_selectedMonth);
    final totalPlanned =
        repository.totalPlannedBudgetExpenseForMonth(_selectedMonth);
    final totalBalance = totalBudget - totalSpent - totalPlanned;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: '月份',
                    border: OutlineInputBorder(),
                  ),
                  items: monthOptions
                      .map(
                        (monthKey) => DropdownMenuItem(
                          value: monthKey,
                          child: Text(monthKey),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryMetric(
                        label: '总预算', value: formatMoney(totalBudget)),
                    _SummaryMetric(label: '实际', value: formatMoney(totalSpent)),
                    _SummaryMetric(
                        label: '预计', value: formatMoney(totalPlanned)),
                    _SummaryMetric(
                        label: '预算池余额', value: formatMoney(totalBalance)),
                  ],
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
            selectedMonth: _selectedMonth,
            isExpanded: _expandedBudgetIds.contains(budget.id),
            onToggleExpanded: () {
              setState(() {
                if (!_expandedBudgetIds.remove(budget.id)) {
                  _expandedBudgetIds.add(budget.id);
                }
              });
            },
            onEdit: () => _showEditBudget(context, budget),
            onDelete: () => widget.onDeleteBudget(budget.id),
          ),
        ),
      ],
    );
  }

  List<String> _buildMonthOptions() {
    final now = DateTime.now();
    return List.generate(
      7,
      (index) => monthKeyFromDate(DateTime(now.year, now.month + index)),
    );
  }

  Future<void> _showAddBudget(BuildContext context) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetFormDialog(repository: widget.repository),
    );
    if (result != null) {
      await widget.onAddBudget(result);
    }
  }

  Future<void> _showEditBudget(BuildContext context, Budget budget) async {
    final result = await showDialog<Budget>(
      context: context,
      builder: (_) => BudgetFormDialog(
        repository: widget.repository,
        initialBudget: budget,
      ),
    );
    if (result != null) {
      await widget.onAddBudget(result);
    }
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.repository,
    required this.selectedMonth,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final FinanceRepository repository;
  final String selectedMonth;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = repository.budgetAmountInBase(budget);
    final effectiveBudget =
        repository.effectiveBudgetForMonth(budget, selectedMonth);
    final spent =
        repository.expenseTotalForCategory(budget.categoryId, selectedMonth);
    final planned = repository.plannedExpenseTotalForCategory(
        budget.categoryId, selectedMonth);
    final monthlyBalance = effectiveBudget - spent - planned;
    final displayCurrency = budget.currency;
    final displayMonthlyBudget =
        repository.convertFromBase(monthlyBudget, displayCurrency);
    final displayEffectiveBudget =
        repository.convertFromBase(effectiveBudget, displayCurrency);
    final displaySpent = repository.convertFromBase(spent, displayCurrency);
    final displayPlanned = repository.convertFromBase(planned, displayCurrency);
    final displayMonthlyBalance =
        repository.convertFromBase(monthlyBalance, displayCurrency);
    final yearKey = selectedMonth.split('-').first;
    final annualBudget = monthlyBudget * 12;
    final annualSpent = List.generate(
      12,
      (index) => '$yearKey-${(index + 1).toString().padLeft(2, '0')}',
    ).fold<double>(
      0,
      (sum, monthKey) =>
          sum + repository.expenseTotalForCategory(budget.categoryId, monthKey),
    );
    final displayAnnualBudget =
        repository.convertFromBase(annualBudget, displayCurrency);
    final displayAnnualSpent =
        repository.convertFromBase(annualSpent, displayCurrency);
    final usage =
        effectiveBudget <= 0 ? 0.0 : (spent / effectiveBudget).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggleExpanded,
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            repository.categoryName(budget.categoryId),
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (budget.rolloverEnabled) ...[
                          const SizedBox(width: 4),
                          Text(
                            '↻',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InlineBudgetSummary(
                    balance: formatMoney(
                      displayMonthlyBalance,
                      currency: displayCurrency,
                    ),
                    budget: formatMoney(
                      displayEffectiveBudget,
                      currency: displayCurrency,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
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
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryMetric(
                    label: '实际',
                    value: formatMoney(displaySpent, currency: displayCurrency),
                  ),
                  _SummaryMetric(
                    label: '预计',
                    value:
                        formatMoney(displayPlanned, currency: displayCurrency),
                  ),
                  _SummaryMetric(
                    label: '月预算',
                    value: formatMoney(
                      displayMonthlyBudget,
                      currency: displayCurrency,
                    ),
                  ),
                  _SummaryMetric(
                    label: '年度预算',
                    value: formatMoney(
                      displayAnnualBudget,
                      currency: displayCurrency,
                    ),
                  ),
                  _SummaryMetric(
                    label: '年内已用',
                    value: formatMoney(
                      displayAnnualSpent,
                      currency: displayCurrency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: usage,
                  backgroundColor:
                      Theme.of(context).dividerColor.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '已用 ${(usage * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineBudgetSummary extends StatelessWidget {
  const _InlineBudgetSummary({
    required this.balance,
    required this.budget,
  });

  final String balance;
  final String budget;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final valueStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: '余额 ',
            style: labelStyle,
            children: [
              TextSpan(text: balance, style: valueStyle),
            ],
          ),
          textAlign: TextAlign.right,
        ),
        Text.rich(
          TextSpan(
            text: '预算 ',
            style: labelStyle,
            children: [
              TextSpan(text: budget, style: valueStyle),
            ],
          ),
          textAlign: TextAlign.right,
        ),
      ],
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}
