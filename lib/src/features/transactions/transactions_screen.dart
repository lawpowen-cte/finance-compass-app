import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/mutations/transaction_mutations.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../categories/category_manage_screen.dart';
import '../shared/finance_action_menu_button.dart';
import '../shared/finance_filter_bar.dart';
import '../shared/finance_metric_card.dart';
import '../shared/finance_status_chip.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import 'transaction_form_dialog.dart';
import '../../core/theme/finance_colors.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.repository,
  });

  final FinanceRepository repository;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final searchController = TextEditingController();
  String? selectedCategoryId;
  String? selectedAccountId;
  String? selectedMonthFrom = monthKeyFromDate(DateTime.now());
  String? selectedMonthTo = monthKeyFromDate(DateTime.now());
  TransactionType? selectedTransactionType;
  TransactionStatus? selectedTransactionStatus;
  String searchQuery = '';
  bool showFilters = false;
  bool showCategories = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String transactionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedTransactionIds.add(transactionId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
        if (_selectedTransactionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _selectAll(List<String> transactionIds) {
    setState(() {
      if (_selectedTransactionIds.length == transactionIds.length) {
        _selectedTransactionIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedTransactionIds.addAll(transactionIds);
      }
    });
  }

  Future<void> _batchDeleteTransactions(BuildContext context) async {
    if (_selectedTransactionIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${_selectedTransactionIds.length} 笔交易吗？'),
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
    );
    
    if (!context.mounted || confirmed != true) return;
    
    for (final id in _selectedTransactionIds) {
      await ref.read(transactionMutationsProvider.notifier).deleteTransaction(id);
    }
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除 ${_selectedTransactionIds.length} 笔交易')),
    );
    
    _exitSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final templates = repository.transactionTemplates;
    final recurringRules = repository.recurringTransactionRules;
    final allCategories = [...repository.sortedCategories()]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final visibleCategories = _visibleCategories(allCategories);
    final effectiveCategoryId =
        visibleCategories.any((item) => item.id == selectedCategoryId)
            ? selectedCategoryId
            : null;
    final accounts = [...repository.accounts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final effectiveAccountId =
        accounts.any((item) => item.id == selectedAccountId)
            ? selectedAccountId
            : null;
    final monthKeys = {
      monthKeyFromDate(DateTime.now()),
      ...repository.transactions
          .map((item) => monthKeyFromDate(item.transactionDate)),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    if (selectedMonthFrom != null && !monthKeys.contains(selectedMonthFrom)) {
      selectedMonthFrom = monthKeyFromDate(DateTime.now());
    }
    if (selectedMonthTo != null && !monthKeys.contains(selectedMonthTo)) {
      selectedMonthTo = monthKeyFromDate(DateTime.now());
    }
    if (selectedMonthFrom != null &&
        selectedMonthTo != null &&
        selectedMonthFrom!.compareTo(selectedMonthTo!) > 0) {
      selectedMonthTo = selectedMonthFrom;
    }
    final normalizedSearchQuery = searchQuery.trim().toLowerCase();

    final filteredTransactions = repository.transactions.where((transaction) {
      final transactionMonthKey = monthKeyFromDate(transaction.transactionDate);
      final matchesCategory = effectiveCategoryId == null ||
          transaction.categoryId == effectiveCategoryId;
      final matchesAccount = effectiveAccountId == null ||
          transaction.accountId == effectiveAccountId ||
          transaction.toAccountId == effectiveAccountId;
      final matchesMonthFrom = selectedMonthFrom == null ||
          transactionMonthKey.compareTo(selectedMonthFrom!) >= 0;
      final matchesMonthTo = selectedMonthTo == null ||
          transactionMonthKey.compareTo(selectedMonthTo!) <= 0;
      final matchesType = selectedTransactionType == null ||
          transaction.type == selectedTransactionType;
      final matchesStatus = selectedTransactionStatus == null ||
          transaction.status == selectedTransactionStatus;
      final matchesSearch = normalizedSearchQuery.isEmpty ||
          _transactionSearchText(repository, transaction)
              .contains(normalizedSearchQuery);
      return matchesCategory &&
          matchesAccount &&
          matchesMonthFrom &&
          matchesMonthTo &&
          matchesType &&
          matchesStatus &&
          matchesSearch;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final totalsByType = <TransactionType, double>{
      for (final type in TransactionType.values) type: 0,
    };
    for (final transaction in filteredTransactions) {
      totalsByType[transaction.type] = (totalsByType[transaction.type] ?? 0) +
          repository.transactionAmountInBase(transaction);
    }
    final actualTransactions = filteredTransactions
        .where((item) => item.status != TransactionStatus.planned);
    final actualIncome = actualTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final actualExpense = actualTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final netCashFlow = actualIncome - actualExpense;

    final allIncome = filteredTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final allExpense = filteredTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final projectedNetCashFlow = allIncome - allExpense;
    final activeFilters = _activeFilters(
      repository: repository,
      accountId: effectiveAccountId,
      categoryId: effectiveCategoryId,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isSelectionMode)
          ScreenHeader(
            title: '交易',
            actions: [
              IconButton.filledTonal(
                onPressed: () => _showCategoryManage(context),
                icon: const Icon(Icons.category_outlined),
                tooltip: '类别管理',
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _showAddTransaction(context),
                icon: const Icon(Icons.add),
                tooltip: '新增交易',
              ),
            ],
          ),
        const SizedBox(height: 12),
        SectionCard(
          title: '快捷录入',
          subtitle: '点按直接使用，右侧菜单维护模板和周期规则',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('快速模板', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              if (templates.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: templates.map((template) {
                    return _TemplateChip(
                      template: template,
                      onTap: () => _showAddTransaction(
                        context,
                        draftTransaction: _draftFromTemplate(template),
                      ),
                      onLongPress: () =>
                          _showTemplateActions(context, template),
                      onAction: (action) async {
                        if (action == 'edit') {
                          await _showAddTransaction(
                            context,
                            draftTransaction: _draftFromTemplate(template),
                          );
                        } else if (action == 'delete') {
                          await _deleteTransactionTemplate(
                            context,
                            template.id,
                          );
                        }
                      },
                    );
                  }).toList(),
                )
              else
                const Text('暂无模板',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
              Text('周期交易', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              if (recurringRules.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: recurringRules.map((rule) {
                    return _RecurringRuleChip(
                      rule: rule,
                      onTap: () =>
                          _generateRecurringTransactions(context, rule),
                      onLongPress: () =>
                          _showRecurringRuleActions(context, rule),
                      onAction: (action) async {
                        if (action == 'generate') {
                          await _generateRecurringTransactions(context, rule);
                        } else if (action == 'delete') {
                          await _deleteRecurringTransactionRule(
                            context,
                            rule.id,
                          );
                        }
                      },
                    );
                  }).toList(),
                )
              else
                const Text('暂无周期规则',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '筛选',
          subtitle: '搜索会匹配说明、商户、账户、类别和交易类型',
          child: FinanceFilterBar(
            searchController: searchController,
            searchQuery: searchQuery,
            searchLabel: '搜索交易',
            onSearchChanged: (value) => setState(() => searchQuery = value),
            onClearSearch: () {
              searchController.clear();
              setState(() => searchQuery = '');
            },
            activeFilters: activeFilters
                .map(
                  (filter) => FinanceFilterChipData(
                    label: filter.label,
                    onClear: filter.onClear,
                  ),
                )
                .toList(),
            onReset: _clearFilters,
            expanded: showFilters,
            onToggleExpanded: () => setState(() => showFilters = !showFilters),
            expandedChild: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: selectedMonthFrom,
                        decoration: const InputDecoration(
                          labelText: '起始月份',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...monthKeys.map(
                            (monthKey) => DropdownMenuItem<String?>(
                              value: monthKey,
                              child: Text(
                                monthLabel(monthKey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedMonthFrom = value;
                          if (selectedMonthFrom != null &&
                              selectedMonthTo != null &&
                              selectedMonthFrom!.compareTo(selectedMonthTo!) >
                                  0) {
                            selectedMonthTo = selectedMonthFrom;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: selectedMonthTo,
                        decoration: const InputDecoration(
                          labelText: '结束月份',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...monthKeys.map(
                            (monthKey) => DropdownMenuItem<String?>(
                              value: monthKey,
                              child: Text(
                                monthLabel(monthKey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedMonthTo = value;
                          if (selectedMonthFrom != null &&
                              selectedMonthTo != null &&
                              selectedMonthFrom!.compareTo(selectedMonthTo!) >
                                  0) {
                            selectedMonthFrom = selectedMonthTo;
                          }
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: effectiveAccountId,
                        decoration: const InputDecoration(
                          labelText: '账户',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...accounts.map(
                            (account) => DropdownMenuItem<String?>(
                              value: account.id,
                              child: Text(
                                account.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedAccountId = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<TransactionType?>(
                        isExpanded: true,
                        value: selectedTransactionType,
                        decoration: const InputDecoration(
                          labelText: '类型',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<TransactionType?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...TransactionType.values.map(
                            (type) => DropdownMenuItem<TransactionType?>(
                              value: type,
                              child: Text(
                                _typeLabel(type),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          selectedTransactionType = value;
                          if (selectedCategoryId != null &&
                              !_visibleCategories(allCategories).any(
                                  (item) => item.id == selectedCategoryId)) {
                            selectedCategoryId = null;
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: effectiveCategoryId,
                        decoration: const InputDecoration(
                          labelText: '类别',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部'),
                          ),
                          ...visibleCategories.map(
                            (category) => DropdownMenuItem<String?>(
                              value: category.id,
                              child: Text(
                                '${category.name} · ${_categoryTypeLabel(category.type)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedCategoryId = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TransactionStatus?>(
                  isExpanded: true,
                  value: selectedTransactionStatus,
                  decoration: const InputDecoration(
                    labelText: '状态',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<TransactionStatus?>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...const [
                      TransactionStatus.planned,
                      TransactionStatus.actual,
                    ].map(
                      (status) => DropdownMenuItem<TransactionStatus?>(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedTransactionStatus = value),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '结果汇总',
          subtitle: '共 ${filteredTransactions.length} 笔',
          child: FinanceMetricGrid(
            minItemWidth: 132,
            maxColumns: 4,
            children: [
              FinanceMetricCard(
                label: '收入',
                value: formatMoney(totalsByType[TransactionType.income] ?? 0),
                color: FinanceColors.income,
              ),
              FinanceMetricCard(
                label: '支出',
                value: formatMoney(totalsByType[TransactionType.expense] ?? 0),
                color: FinanceColors.expense,
              ),
              FinanceMetricCard(
                label: '净现金流',
                value: formatMoney(netCashFlow),
                color: netCashFlow >= 0
                    ? FinanceColors.income
                    : FinanceColors.expense,
              ),
              FinanceMetricCard(
                label: '净现金流（含预计）',
                value: formatMoney(projectedNetCashFlow),
                color: projectedNetCashFlow >= 0
                    ? FinanceColors.income
                    : FinanceColors.expense,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isSelectionMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _exitSelectionMode,
                  icon: const Icon(Icons.close),
                  tooltip: '取消',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '已选择 ${_selectedTransactionIds.length} 笔',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _selectAll(
                    filteredTransactions.map((t) => t.id).toList(),
                  ),
                  child: Text(
                    _selectedTransactionIds.length == filteredTransactions.length
                        ? '取消全选'
                        : '全选',
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _selectedTransactionIds.isNotEmpty
                      ? () => _batchDeleteTransactions(context)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ),
        if (_isSelectionMode) const SizedBox(height: 8),
        SectionCard(
          title: '交易列表',
          subtitle: '共 ${filteredTransactions.length} 笔',
          child: filteredTransactions.isEmpty
              ? const Text('暂无交易')
              : Column(
                  children: filteredTransactions.map((transaction) {
                    final categoryName = transaction.categoryId == null
                        ? null
                        : _categoryNameOrFallback(
                            repository, transaction.categoryId!);
                    final hint =
                        _displayConversionHint(repository, transaction);
                    final isSelected = _selectedTransactionIds.contains(transaction.id);
                    return GestureDetector(
                      onLongPress: () => _enterSelectionMode(transaction.id),
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(transaction.id)
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.4),
                            width: isSelected ? 1.5 : 0.6,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 20,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _displayAmount(transaction),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _amountColor(transaction.type),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _typeLabel(transaction.type),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: _amountColor(transaction.type),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hint.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(hint,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(fontSize: 10)),
                                    ),
                                  if (_isMeaningfulDescription(transaction))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 1),
                                      child: Text(
                                        transaction.description!,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 3,
                                    children: [
                                      FinanceStatusChip(
                                        label: _accountFlowLabel(
                                            repository, transaction),
                                      ),
                                      if (categoryName != null)
                                        FinanceStatusChip(label: categoryName),
                                      if (transaction.status ==
                                          TransactionStatus.planned)
                                        const FinanceStatusChip(
                                          label: '预计',
                                          color: Color(0xFFB45309),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!_isSelectionMode) ...[
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${transaction.transactionDate.day.toString().padLeft(2, '0')}-${transaction.transactionDate.month.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                  FinanceActionMenuButton<String>(
                                    iconSize: 16,
                                    tooltip: '交易操作',
                                    items: const [
                                      FinanceActionMenuItem(
                                        value: 'edit',
                                        label: '编辑',
                                        icon: Icons.edit_outlined,
                                      ),
                                      FinanceActionMenuItem(
                                        value: 'reuse',
                                        label: '复用新增',
                                        icon: Icons.copy_outlined,
                                      ),
                                      FinanceActionMenuItem(
                                        value: 'template',
                                        label: '保存模板',
                                        icon: Icons.bolt_outlined,
                                      ),
                                      FinanceActionMenuItem(
                                        value: 'recurring',
                                        label: '保存周期',
                                        icon: Icons.repeat,
                                      ),
                                      FinanceActionMenuItem(
                                        value: 'delete',
                                        label: '删除',
                                        icon: Icons.delete_outline,
                                        destructive: true,
                                        dividerBefore: true,
                                      ),
                                    ],
                                    onSelected: (value) => _handleTransactionAction(
                                      context,
                                      value,
                                      transaction,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  List<_ActiveFilterData> _activeFilters({
    required FinanceRepository repository,
    required String? accountId,
    required String? categoryId,
  }) {
    final filters = <_ActiveFilterData>[];
    if (searchQuery.trim().isNotEmpty) {
      filters.add(
        _ActiveFilterData(
          label: '搜索: ${searchQuery.trim()}',
          onClear: () {
            searchController.clear();
            setState(() => searchQuery = '');
          },
        ),
      );
    }

    final monthLabelText = selectedMonthFrom == null && selectedMonthTo == null
        ? '全部月份'
        : selectedMonthFrom == selectedMonthTo
            ? monthLabel(selectedMonthFrom!)
            : '${selectedMonthFrom == null ? '最早' : monthLabel(selectedMonthFrom!)}'
                ' - ${selectedMonthTo == null ? '最新' : monthLabel(selectedMonthTo!)}';
    filters.add(
      _ActiveFilterData(
        label: monthLabelText,
        onClear: () => setState(() {
          selectedMonthFrom = null;
          selectedMonthTo = null;
        }),
      ),
    );

    if (accountId != null) {
      filters.add(
        _ActiveFilterData(
          label: repository.accountName(accountId),
          onClear: () => setState(() => selectedAccountId = null),
        ),
      );
    }
    if (selectedTransactionType != null) {
      filters.add(
        _ActiveFilterData(
          label: _typeLabel(selectedTransactionType!),
          onClear: () => setState(() {
            selectedTransactionType = null;
            selectedCategoryId = null;
          }),
        ),
      );
    }
    if (categoryId != null) {
      filters.add(
        _ActiveFilterData(
          label: _categoryNameOrFallback(repository, categoryId),
          onClear: () => setState(() => selectedCategoryId = null),
        ),
      );
    }
    if (selectedTransactionStatus != null) {
      filters.add(
        _ActiveFilterData(
          label: _statusLabel(selectedTransactionStatus!),
          onClear: () => setState(() => selectedTransactionStatus = null),
        ),
      );
    }
    return filters;
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      searchQuery = '';
      selectedCategoryId = null;
      selectedAccountId = null;
      selectedMonthFrom = monthKeyFromDate(DateTime.now());
      selectedMonthTo = monthKeyFromDate(DateTime.now());
      selectedTransactionType = null;
      selectedTransactionStatus = null;
    });
  }

  String _transactionSearchText(
    FinanceRepository repository,
    FinanceTransaction transaction,
  ) {
    final categoryName = transaction.categoryId == null
        ? ''
        : _categoryNameOrFallback(repository, transaction.categoryId!);
    final parts = [
      transaction.description ?? '',
      transaction.merchant ?? '',
      _typeLabel(transaction.type),
      _statusLabel(transaction.status),
      _accountFlowLabel(repository, transaction),
      categoryName,
      transaction.currency,
      transaction.transferInCurrency,
      transaction.amount.toStringAsFixed(2),
      transaction.transferInAmount.toStringAsFixed(2),
    ];
    return parts.join(' ').toLowerCase();
  }

  String _accountFlowLabel(
    FinanceRepository repository,
    FinanceTransaction transaction,
  ) {
    final source = repository.accountName(transaction.accountId);
    final targetId = transaction.toAccountId;
    if (transaction.type != TransactionType.transfer || targetId == null) {
      return source;
    }
    return '$source -> ${repository.accountName(targetId)}';
  }

  List<Category> _visibleCategories(List<Category> categories) {
    if (selectedTransactionType == null) {
      return categories;
    }
    switch (selectedTransactionType!) {
      case TransactionType.income:
        return categories
            .where((item) => item.type == CategoryType.income)
            .toList();
      case TransactionType.expense:
        return categories
            .where((item) => item.type == CategoryType.expense)
            .toList();
      case TransactionType.transfer:
      case TransactionType.adjustment:
        return categories
            .where((item) =>
                item.type == CategoryType.transfer ||
                item.type == CategoryType.investment)
            .toList();
    }
  }



  Future<void> _deleteTransactionTemplate(
      BuildContext context, String templateId) async {
    await ref
        .read(transactionMutationsProvider.notifier)
        .deleteTransactionTemplate(templateId);
  }

  Future<void> _deleteRecurringTransactionRule(
      BuildContext context, String ruleId) async {
    await ref
        .read(transactionMutationsProvider.notifier)
        .deleteRecurringTransactionRule(ruleId);
  }

  Future<void> _showTemplateActions(
      BuildContext context, TransactionTemplate template) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(template.name),
        children: [
          SimpleDialogOption(
            child: const Text('编辑'),
            onPressed: () => Navigator.pop(ctx, 'edit'),
          ),
          SimpleDialogOption(
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _showAddTransaction(
        context,
        draftTransaction: _draftFromTemplate(template),
      );
    } else if (action == 'delete') {
      await _deleteTransactionTemplate(context, template.id);
    }
  }

  Future<void> _showRecurringRuleActions(
      BuildContext context, RecurringTransactionRule rule) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(rule.name),
        children: [
          SimpleDialogOption(
            child: const Text('生成'),
            onPressed: () => Navigator.pop(ctx, 'generate'),
          ),
          SimpleDialogOption(
            child: const Text('删除'),
            onPressed: () => Navigator.pop(ctx, 'delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (action == 'generate') {
      await _generateRecurringTransactions(context, rule);
    } else if (action == 'delete') {
      await _deleteRecurringTransactionRule(context, rule.id);
    }
  }

  Future<void> _handleTransactionAction(
    BuildContext context,
    String value,
    FinanceTransaction transaction,
  ) async {
    if (value == 'edit') {
      await _showEditTransaction(context, transaction);
      return;
    }
    if (value == 'reuse') {
      await _showAddTransaction(
        context,
        draftTransaction: _draftFromTransaction(transaction),
      );
      return;
    }
    if (value == 'template') {
      await _saveTransactionTemplate(context, transaction);
      return;
    }
    if (value == 'recurring') {
      await _saveRecurringRule(context, transaction);
      return;
    }
    if (value == 'delete') {
      await ref
          .read(transactionMutationsProvider.notifier)
          .deleteTransaction(transaction.id);
    }
  }

  Future<void> _saveTransactionTemplate(
    BuildContext context,
    FinanceTransaction transaction,
  ) async {
    final controller = TextEditingController(
      text: transaction.description ??
          transaction.merchant ??
          _categoryNameOrFallback(
            widget.repository,
            transaction.categoryId ?? '',
          ),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存为模板'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '模板名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || name == null || name.trim().isEmpty) {
      return;
    }
    await ref
        .read(transactionMutationsProvider.notifier)
        .addTransactionTemplate(
          name: name.trim(),
          transaction: transaction,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('模板「${name.trim()}」已保存')),
    );
  }

  Future<void> _saveRecurringRule(
    BuildContext context,
    FinanceTransaction transaction,
  ) async {
    final nameController = TextEditingController(
      text: transaction.description ??
          transaction.merchant ??
          _categoryNameOrFallback(
            widget.repository,
            transaction.categoryId ?? '',
          ),
    );
    var intervalMonths = 1;
    final result = await showDialog<_RecurringRuleDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('保存为周期规则'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '规则名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: intervalMonths,
                decoration: const InputDecoration(
                  labelText: '重复间隔',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('每月')),
                  DropdownMenuItem(value: 2, child: Text('每 2 个月')),
                  DropdownMenuItem(value: 3, child: Text('每季')),
                  DropdownMenuItem(value: 12, child: Text('每年')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => intervalMonths = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _RecurringRuleDraft(
                  name: nameController.text.trim(),
                  intervalMonths: intervalMonths,
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (!context.mounted || result == null || result.name.isEmpty) {
      return;
    }
    await ref
        .read(transactionMutationsProvider.notifier)
        .addRecurringTransactionRule(
          name: result.name,
          transaction: transaction,
          intervalMonths: result.intervalMonths,
        );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('周期规则「${result.name}」已保存')),
    );
  }

  Future<void> _generateRecurringTransactions(
    BuildContext context,
    RecurringTransactionRule rule,
  ) async {
    final months = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('生成周期交易', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  return ChoiceChip(
                    label: Text('$month 个月'),
                    selected: false,
                    onSelected: (_) => Navigator.of(context).pop(month),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || months == null) {
      return;
    }
    await ref
        .read(transactionMutationsProvider.notifier)
        .generateRecurringTransactions(rule.id, monthsAhead: months);
  }

  FinanceTransaction _draftFromTemplate(TransactionTemplate template) {
    final now = DateTime.now();
    return FinanceTransaction(
      id: 'draft_${template.id}',
      type: template.type,
      accountId: template.accountId,
      toAccountId: template.toAccountId,
      categoryId: template.categoryId,
      amount: template.amount,
      currency: template.currency,
      toAmount: template.toAmount,
      toCurrency: template.toCurrency,
      recordDate: now,
      transactionDate: now,
      status: template.status,
      description: template.description,
      merchant: template.merchant,
    );
  }

  FinanceTransaction _draftFromTransaction(FinanceTransaction transaction) {
    final now = DateTime.now();
    return FinanceTransaction(
      id: 'draft_${transaction.id}',
      type: transaction.type,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      currency: transaction.currency,
      toAmount: transaction.toAmount,
      toCurrency: transaction.toCurrency,
      recordDate: now,
      transactionDate: now,
      status: transaction.status,
      description: transaction.description,
      merchant: transaction.merchant,
    );
  }

  String _categoryNameOrFallback(
    FinanceRepository repository,
    String categoryId,
  ) {
    if (categoryId.isEmpty) {
      return '常用交易';
    }
    try {
      return repository.categoryName(categoryId);
    } catch (_) {
      return '未命名类别';
    }
  }

  bool _isMeaningfulDescription(FinanceTransaction transaction) {
    final desc = transaction.description?.trim();
    if (desc == null || desc.isEmpty) return false;
    final typeLabel = _typeLabel(transaction.type);
    return desc != typeLabel;
  }

  Color _amountColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return FinanceColors.expense;
      case TransactionType.transfer:
        return FinanceColors.transfer;
      case TransactionType.income:
        return FinanceColors.income;
      case TransactionType.adjustment:
        return FinanceColors.adjustment;
    }
  }

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
      case TransactionType.transfer:
        return '转账';
      case TransactionType.adjustment:
        return '注资调整';
    }
  }

  String _categoryTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return '收入';
      case CategoryType.expense:
        return '支出';
      case CategoryType.investment:
        return '投资';
      case CategoryType.transfer:
        return '转账';
    }
  }

  String _statusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.planned:
        return '预计';
      case TransactionStatus.actual:
        return '已发生';
      case TransactionStatus.settled:
        return '已发生';
    }
  }

  Future<void> _showAddTransaction(
    BuildContext context, {
    FinanceTransaction? draftTransaction,
  }) async {
    final result = await showDialog<TransactionFormResult>(
      context: context,
      builder: (_) => TransactionFormDialog(
        repository: widget.repository,
        draftTransaction: draftTransaction,
      ),
    );
    if (result != null) {
      if (result.transactions.length == 1) {
        await ref
            .read(transactionMutationsProvider.notifier)
            .addTransaction(result.transactions.first);
      } else {
        await ref
            .read(transactionMutationsProvider.notifier)
            .addTransactions(result.transactions);
      }
    }
  }

  Future<void> _showEditTransaction(
      BuildContext context, FinanceTransaction transaction) async {
    final result = await showDialog<TransactionFormResult>(
      context: context,
      builder: (_) => TransactionFormDialog(
        repository: widget.repository,
        initialTransaction: transaction,
      ),
    );
    if (result != null) {
      await ref
          .read(transactionMutationsProvider.notifier)
          .updateTransaction(result.transactions.first);
    }
  }

  Future<void> _showCategoryManage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryManageScreen(repository: widget.repository),
      ),
    );
  }

  String _displayAmount(FinanceTransaction transaction) {
    switch (transaction.type) {
      case TransactionType.expense:
        return '-${formatMoney(transaction.amount, currency: transaction.currency)}';
      case TransactionType.transfer:
        return '${formatMoney(transaction.amount, currency: transaction.currency)} → '
            '${formatMoney(transaction.transferInAmount, currency: transaction.transferInCurrency)}';
      case TransactionType.income:
      case TransactionType.adjustment:
        return '+${formatMoney(transaction.amount, currency: transaction.currency)}';
    }
  }

  String _displayConversionHint(
    FinanceRepository repository,
    FinanceTransaction transaction,
  ) {
    if (transaction.type == TransactionType.transfer) {
      if (transaction.currency == repository.baseCurrency &&
          transaction.transferInCurrency == repository.baseCurrency) {
        return '';
      }
      final sourceHint = formatConversionHint(
        amount: transaction.amount,
        fromCurrency: transaction.currency,
        toCurrency: transaction.transferInCurrency,
        ratesToBase: repository.exchangeRatesToBase,
        baseCurrency: repository.baseCurrency,
      );
      final targetHint = formatConversionHint(
        amount: transaction.transferInAmount,
        fromCurrency: transaction.transferInCurrency,
        toCurrency: repository.baseCurrency,
        ratesToBase: repository.exchangeRatesToBase,
        baseCurrency: repository.baseCurrency,
      );
      if (sourceHint == targetHint) {
        return sourceHint;
      }
      return '$sourceHint / $targetHint';
    }
    if (transaction.currency == repository.baseCurrency) {
      return '';
    }
    return repository.conversionHintForAmount(
      transaction.amount,
      transaction.currency,
    );
  }
}

class _ActiveFilterData {
  const _ActiveFilterData({
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;
}

class _RecurringRuleChip extends StatelessWidget {
  const _RecurringRuleChip({
    required this.rule,
    required this.onTap,
    required this.onLongPress,
    required this.onAction,
  });

  final RecurringTransactionRule rule;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(
              rule.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.85),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 24,
              height: 24,
              child: FinanceActionMenuButton<String>(
                iconSize: 16,
                tooltip: '周期交易操作',
                onSelected: onAction,
                items: const [
                  FinanceActionMenuItem(
                    value: 'generate',
                    label: '生成',
                    icon: Icons.playlist_add_outlined,
                  ),
                  FinanceActionMenuItem(
                    value: 'delete',
                    label: '删除',
                    icon: Icons.delete_outline,
                    destructive: true,
                    dividerBefore: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringRuleDraft {
  const _RecurringRuleDraft({
    required this.name,
    required this.intervalMonths,
  });

  final String name;
  final int intervalMonths;
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.onTap,
    required this.onLongPress,
    required this.onAction,
  });

  final TransactionTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(
              template.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.85),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 2),
            SizedBox(
              width: 24,
              height: 24,
              child: FinanceActionMenuButton<String>(
                iconSize: 16,
                tooltip: '模板操作',
                onSelected: onAction,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
