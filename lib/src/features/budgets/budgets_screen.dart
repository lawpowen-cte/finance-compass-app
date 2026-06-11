import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/budget.dart';
import '../../core/providers/mutations/budget_mutations.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../shared/finance_action_menu_button.dart';
import '../shared/finance_metric_card.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import 'budget_form_dialog.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late String _selectedMonth;
  final _expandedBudgetIds = <String>{};
  final _collapsedBudgets = <String>{};
  List<String> _budgetOrder = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = monthKeyFromDate(DateTime.now());
    _loadCollapsedBudgets();
    _loadBudgetOrder();
  }

  Future<void> _loadCollapsedBudgets() async {
    final raw = await DatabaseProvider.instance.getMetaValue('collapsed_budgets');
    if (raw != null && mounted) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _collapsedBudgets.addAll(decoded.cast<String>());
        });
      } catch (_) {
        // ignore parse errors
      }
    }
  }

  Future<void> _toggleBudgetCollapse(String budgetId) async {
    setState(() {
      if (_collapsedBudgets.contains(budgetId)) {
        _collapsedBudgets.remove(budgetId);
      } else {
        _collapsedBudgets.add(budgetId);
      }
    });
    await DatabaseProvider.instance.setMetaValue(
      'collapsed_budgets',
      jsonEncode(_collapsedBudgets.toList()),
    );
  }

  Future<void> _loadBudgetOrder() async {
    final raw = await DatabaseProvider.instance.getMetaValue('budget_order');
    if (raw != null && mounted) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        setState(() {
          _budgetOrder = decoded.cast<String>();
        });
      } catch (_) {
        // ignore parse errors
      }
    }
  }

  Future<void> _saveBudgetOrder(List<String> order) async {
    setState(() {
      _budgetOrder = order;
    });
    await DatabaseProvider.instance.setMetaValue(
      'budget_order',
      jsonEncode(order),
    );
  }

  void _reorderBudgets(int oldIndex, int newIndex) {
    final budgets = widget.repository.activeBudgetsForMonth(_selectedMonth);
    final budgetIds = budgets.map((b) => b.id).toList();
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final newOrder = List<String>.from(budgetIds);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    
    _saveBudgetOrder(newOrder);
  }

  List<Budget> _sortBudgets(List<Budget> budgets) {
    if (_budgetOrder.isEmpty) return budgets;
    
    final sorted = <Budget>[];
    for (final id in _budgetOrder) {
      final budget = budgets.firstWhere(
        (b) => b.id == id,
        orElse: () => budgets.first,
      );
      if (!sorted.contains(budget)) {
        sorted.add(budget);
      }
    }
    
    for (final budget in budgets) {
      if (!sorted.contains(budget)) {
        sorted.add(budget);
      }
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final monthOptions = _buildMonthOptions();
    if (!monthOptions.contains(_selectedMonth)) {
      _selectedMonth = monthOptions.first;
    }
    final budgets = repository.activeBudgetsForMonth(_selectedMonth);

    final totalBudget = repository.totalEffectiveBudgetForMonth(_selectedMonth);
    final totalSpent = repository.totalBudgetExpenseForMonth(_selectedMonth);
    final totalPlanned = repository.totalPlannedBudgetExpenseForMonth(
      _selectedMonth,
    );
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
        SectionCard(
          title: '预算概览',
          subtitle: '实际与预计都会占用预算池',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: '月份',
                  border: OutlineInputBorder(),
                  isDense: true,
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
              const SizedBox(height: 14),
              FinanceMetricGrid(
                fixedColumns: 2,
                maxColumns: 2,
                minItemWidth: 168,
                children: [
                  FinanceMetricCard(
                    label: '总预算',
                    value: formatMoney(totalBudget),
                    tone: FinanceMetricTone.neutral,
                  ),
                  FinanceMetricCard(
                    label: '实际',
                    value: formatMoney(totalSpent),
                    tone: FinanceMetricTone.expense,
                  ),
                  FinanceMetricCard(
                    label: '预计',
                    value: formatMoney(totalPlanned),
                    tone: FinanceMetricTone.warning,
                  ),
                  FinanceMetricCard(
                    label: '预算池余额',
                    value: formatMoney(totalBalance),
                    tone: totalBalance >= 0
                        ? FinanceMetricTone.income
                        : FinanceMetricTone.expense,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (budgets.isEmpty)
          const SectionCard(title: '预算列表', child: Text('还没有预算，先新增一笔。')),
        if (budgets.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderBudgets,
            children: _sortBudgets(budgets).map(
              (budget) => _BudgetTile(
                budget: budget,
                repository: repository,
                selectedMonth: _selectedMonth,
                isExpanded: _expandedBudgetIds.contains(budget.id),
                isCollapsed: _collapsedBudgets.contains(budget.id),
                onToggleExpanded: () {
                  setState(() {
                    if (!_expandedBudgetIds.remove(budget.id)) {
                      _expandedBudgetIds.add(budget.id);
                    }
                  });
                },
                onToggleCollapsed: () => _toggleBudgetCollapse(budget.id),
                onEdit: () => _showEditBudget(context, budget),
                onDelete: () => _confirmDeleteBudget(context, budget),
              ),
            ).toList(),
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
      await ref.read(budgetMutationsProvider.notifier).addBudget(result);
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
      await ref.read(budgetMutationsProvider.notifier).addBudget(result);
    }
  }

  Future<void> _confirmDeleteBudget(BuildContext context, Budget budget) async {
    final categoryName = widget.repository.categoryName(budget.categoryId);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('删除预算'),
            content: Text('确定删除“$categoryName”的预算规则吗？'),
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
    await ref.read(budgetMutationsProvider.notifier).deleteBudget(budget.id);
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.repository,
    required this.selectedMonth,
    required this.isExpanded,
    required this.isCollapsed,
    required this.onToggleExpanded,
    required this.onToggleCollapsed,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final FinanceRepository repository;
  final String selectedMonth;
  final bool isExpanded;
  final bool isCollapsed;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleCollapsed;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  String _calculateDailyBalance(double balance, String monthKey, String currency) {
    final now = DateTime.now();
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = now.day;
    final remainingDays = daysInMonth - today + 1;
    if (remainingDays <= 0) return formatMoney(0, currency: currency);
    final dailyAmount = balance / remainingDays;
    return formatMoney(dailyAmount, currency: currency);
  }

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = repository.budgetAmountInBase(budget);
    final effectiveBudget = repository.effectiveBudgetForMonth(
      budget,
      selectedMonth,
    );
    final spent = repository.expenseTotalForCategory(
      budget.categoryId,
      selectedMonth,
    );
    final planned = repository.plannedExpenseTotalForCategory(
      budget.categoryId,
      selectedMonth,
    );
    final monthlyBalance = effectiveBudget - spent - planned;
    final displayCurrency = budget.currency;
    final displayMonthlyBudget = repository.convertFromBase(
      monthlyBudget,
      displayCurrency,
    );
    final displayEffectiveBudget = repository.convertFromBase(
      effectiveBudget,
      displayCurrency,
    );
    final displaySpent = repository.convertFromBase(spent, displayCurrency);
    final displayPlanned = repository.convertFromBase(planned, displayCurrency);
    final displayMonthlyBalance = repository.convertFromBase(
      monthlyBalance,
      displayCurrency,
    );
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
    final displayAnnualBudget = repository.convertFromBase(
      annualBudget,
      displayCurrency,
    );
    final displayAnnualSpent = repository.convertFromBase(
      annualSpent,
      displayCurrency,
    );
    final usage =
        effectiveBudget <= 0 ? 0.0 : (spent / effectiveBudget).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
                  GestureDetector(
                    onTap: onToggleCollapsed,
                    child: Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
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
                          Tooltip(
                            message: '结转已开启',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: const Color(
                                  0xFFE8A838,
                                ).withValues(alpha: 0.14),
                              ),
                              child: Text(
                                '结转',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFFE8A838),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
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
                    isCollapsed: isCollapsed,
                    dailyBalance: _calculateDailyBalance(
                      displayMonthlyBalance,
                      selectedMonth,
                      displayCurrency,
                    ),
                  ),
                  FinanceActionMenuButton<String>(
                    tooltip: '预算操作',
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
                        dividerBefore: true,
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await onEdit();
                      }
                      if (value == 'delete') {
                        await onDelete();
                      }
                    },
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              FinanceMetricGrid(
                gap: 8,
                minItemWidth: 136,
                maxColumns: 3,
                children: [
                  FinanceMetricCard(
                    label: '实际',
                    value: formatMoney(displaySpent, currency: displayCurrency),
                  ),
                  FinanceMetricCard(
                    label: '预计',
                    value: formatMoney(
                      displayPlanned,
                      currency: displayCurrency,
                    ),
                  ),
                  FinanceMetricCard(
                    label: '月预算',
                    value: formatMoney(
                      displayMonthlyBudget,
                      currency: displayCurrency,
                    ),
                  ),
                  FinanceMetricCard(
                    label: '年度预算',
                    value: formatMoney(
                      displayAnnualBudget,
                      currency: displayCurrency,
                    ),
                  ),
                  FinanceMetricCard(
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
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.35),
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
    this.isCollapsed = false,
    this.dailyBalance,
  });

  final String balance;
  final String budget;
  final bool isCollapsed;
  final String? dailyBalance;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final valueStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCollapsed && dailyBalance != null)
          Text.rich(
            TextSpan(
              text: '可用/天 ',
              style: labelStyle,
              children: [TextSpan(text: dailyBalance!, style: valueStyle)],
            ),
            textAlign: TextAlign.right,
          )
        else ...[
          Text.rich(
            TextSpan(
              text: '余额 ',
              style: labelStyle,
              children: [TextSpan(text: balance, style: valueStyle)],
            ),
            textAlign: TextAlign.right,
          ),
          Text.rich(
            TextSpan(
              text: '预算 ',
              style: labelStyle,
              children: [TextSpan(text: budget, style: valueStyle)],
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ],
    );
  }
}
