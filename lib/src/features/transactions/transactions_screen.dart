import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../categories/category_form_dialog.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import 'transaction_form_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.repository,
    required this.onAddTransaction,
    required this.onAddTransactions,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onAddTransactionTemplate,
    required this.onDeleteTransactionTemplate,
    required this.onAddRecurringTransactionRule,
    required this.onDeleteRecurringTransactionRule,
    required this.onGenerateRecurringTransactions,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  final FinanceRepository repository;
  final Future<void> Function(FinanceTransaction transaction) onAddTransaction;
  final Future<void> Function(List<FinanceTransaction> transactions)
      onAddTransactions;
  final Future<void> Function(FinanceTransaction transaction) onEditTransaction;
  final Future<void> Function(String transactionId) onDeleteTransaction;
  final Future<void> Function(String name, FinanceTransaction transaction)
      onAddTransactionTemplate;
  final Future<void> Function(String templateId) onDeleteTransactionTemplate;
  final Future<void> Function(
    String name,
    FinanceTransaction transaction,
    int intervalMonths,
  ) onAddRecurringTransactionRule;
  final Future<void> Function(String ruleId) onDeleteRecurringTransactionRule;
  final Future<void> Function(String ruleId, int monthsAhead)
      onGenerateRecurringTransactions;
  final Future<void> Function(Category category) onAddCategory;
  final Future<void> Function(Category category) onUpdateCategory;
  final Future<bool> Function(String categoryId) onDeleteCategory;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? selectedCategoryId;
  String? selectedAccountId;
  String? selectedMonthFrom = monthKeyFromDate(DateTime.now());
  String? selectedMonthTo = monthKeyFromDate(DateTime.now());
  TransactionType? selectedTransactionType;
  TransactionStatus? selectedTransactionStatus;
  bool showTemplates = false;
  bool showRecurringRules = false;
  bool showCategories = false;

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
      return matchesCategory &&
          matchesAccount &&
          matchesMonthFrom &&
          matchesMonthTo &&
          matchesType &&
          matchesStatus;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final totalsByType = <TransactionType, double>{
      for (final type in TransactionType.values) type: 0,
    };
    for (final transaction in filteredTransactions) {
      totalsByType[transaction.type] = (totalsByType[transaction.type] ?? 0) +
          repository.transactionAmountInBase(transaction);
    }
    final plannedTotal = filteredTransactions
        .where((item) => item.status == TransactionStatus.planned)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final actualTotal = filteredTransactions
        .where((item) => item.status != TransactionStatus.planned)
        .fold<double>(
            0, (sum, item) => sum + repository.transactionAmountInBase(item));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScreenHeader(
          title: '交易',
          actions: [
            IconButton.filledTonal(
              onPressed: () => _showAddCategory(context),
              icon: const Icon(Icons.category_outlined),
              tooltip: '新增类别',
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
          title: '快速模板',
          subtitle: templates.isEmpty ? '可从交易列表保存常用交易' : null,
          child: templates.isEmpty
              ? const Text('暂无模板')
              : _CollapsibleList(
                  isExpanded: showTemplates,
                  collapsedLabel: '展开 ${templates.length} 个模板',
                  expandedLabel: '收起模板',
                  onToggle: () =>
                      setState(() => showTemplates = !showTemplates),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: templates.map((template) {
                      return _TemplateChip(
                        template: template,
                        accountLabel: _accountNameOrFallback(
                            repository, template.accountId),
                        categoryLabel: template.categoryId == null
                            ? null
                            : _categoryNameOrFallback(
                                repository,
                                template.categoryId!,
                              ),
                        onUse: () => _showAddTransaction(
                          context,
                          draftTransaction: _draftFromTemplate(template),
                        ),
                        onDelete: () =>
                            widget.onDeleteTransactionTemplate(template.id),
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '周期交易',
          subtitle: recurringRules.isEmpty ? '可从交易列表保存一笔为周期规则' : null,
          child: recurringRules.isEmpty
              ? const Text('暂无周期规则')
              : _CollapsibleList(
                  isExpanded: showRecurringRules,
                  collapsedLabel: '展开 ${recurringRules.length} 个周期规则',
                  expandedLabel: '收起周期规则',
                  onToggle: () =>
                      setState(() => showRecurringRules = !showRecurringRules),
                  child: Column(
                    children: recurringRules
                        .map(
                          (rule) => _RecurringRuleTile(
                            rule: rule,
                            accountLabel: _accountNameOrFallback(
                                repository, rule.accountId),
                            categoryLabel: rule.categoryId == null
                                ? null
                                : _categoryNameOrFallback(
                                    repository,
                                    rule.categoryId!,
                                  ),
                            onGenerate: () =>
                                _generateRecurringTransactions(context, rule),
                            onDelete: () => widget
                                .onDeleteRecurringTransactionRule(rule.id),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '筛选',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: selectedMonthFrom,
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
                      initialValue: selectedMonthTo,
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
                      initialValue: effectiveAccountId,
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
                      initialValue: selectedTransactionType,
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
                            !_visibleCategories(allCategories)
                                .any((item) => item.id == selectedCategoryId)) {
                          selectedCategoryId = null;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: effectiveCategoryId,
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
                initialValue: selectedTransactionStatus,
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
        const SizedBox(height: 12),
        SectionCard(
          title: '结果汇总',
          subtitle: '共 ${filteredTransactions.length} 笔',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TypeTotalChip(
                label: '收入',
                value: totalsByType[TransactionType.income] ?? 0,
                color: const Color(0xFF15803D),
              ),
              _TypeTotalChip(
                label: '支出',
                value: totalsByType[TransactionType.expense] ?? 0,
                color: const Color(0xFFB91C1C),
              ),
              _TypeTotalChip(
                label: '转账',
                value: totalsByType[TransactionType.transfer] ?? 0,
                color: const Color(0xFF475569),
              ),
              _TypeTotalChip(
                label: '注资调整',
                value: totalsByType[TransactionType.adjustment] ?? 0,
                color: const Color(0xFF0369A1),
              ),
              _TypeTotalChip(
                label: '预计',
                value: plannedTotal,
                color: const Color(0xFFB45309),
              ),
              _TypeTotalChip(
                label: '实际',
                value: actualTotal,
                color: const Color(0xFF0F766E),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '类别',
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => showCategories = !showCategories),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(showCategories ? '收起类别' : '展开类别')),
                      Icon(showCategories
                          ? Icons.expand_less
                          : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (showCategories) ...[
                const SizedBox(height: 12),
                ...visibleCategories.map((category) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color:
                          Theme.of(context).cardColor.withValues(alpha: 0.86),
                      border: Border.all(color: Theme.of(context).cardColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _categoryTypeLabel(category.type),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showEditCategory(context, category),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: '编辑类别',
                        ),
                        IconButton(
                          onPressed: () => _deleteCategory(context, category),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '删除类别',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '交易列表',
          subtitle: '共 ${filteredTransactions.length} 笔',
          child: filteredTransactions.isEmpty
              ? const Text('暂无交易')
              : Column(
                  children: filteredTransactions.map((transaction) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color:
                            Theme.of(context).cardColor.withValues(alpha: 0.86),
                        border: Border.all(color: Theme.of(context).cardColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.description ??
                                      transaction.merchant ??
                                      _typeLabel(transaction.type),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _transactionMeta(repository, transaction),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _displayAmount(transaction),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _amountColor(transaction.type),
                                ),
                              ),
                              if (_displayConversionHint(
                                      repository, transaction)
                                  .isNotEmpty)
                                Text(
                                  _displayConversionHint(
                                      repository, transaction),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (value) => _handleTransactionAction(
                                  context,
                                  value,
                                  transaction,
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('编辑')),
                                  PopupMenuItem(
                                      value: 'reuse', child: Text('复用新增')),
                                  PopupMenuItem(
                                      value: 'template', child: Text('保存模板')),
                                  PopupMenuItem(
                                      value: 'recurring', child: Text('保存周期')),
                                  PopupMenuDivider(),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('删除')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
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

  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final deleted = await widget.onDeleteCategory(category.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? '类别已删除' : '该类别已关联预算或交易，不能删除',
        ),
      ),
    );
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
      await widget.onDeleteTransaction(transaction.id);
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
    await widget.onAddTransactionTemplate(name.trim(), transaction);
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
                initialValue: intervalMonths,
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
    await widget.onAddRecurringTransactionRule(
      result.name,
      transaction,
      result.intervalMonths,
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
    await widget.onGenerateRecurringTransactions(rule.id, months);
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

  String _accountNameOrFallback(
    FinanceRepository repository,
    String accountId,
  ) {
    try {
      return repository.accountName(accountId);
    } catch (_) {
      return '未知账户';
    }
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

  String _transactionMeta(
      FinanceRepository repository, FinanceTransaction transaction) {
    final categoryName = transaction.categoryId == null
        ? null
        : repository.categoryName(transaction.categoryId!);
    final recordDateLabel = _dateLabel(transaction.recordDate);
    final settlementDateLabel = _dateLabel(transaction.transactionDate);
    return [
      _typeLabel(transaction.type),
      repository.accountName(transaction.accountId),
      if (categoryName != null) categoryName,
      _statusLabel(transaction.status),
      '记录 $recordDateLabel',
      '结算 $settlementDateLabel',
    ].join(' · ');
  }

  String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color _amountColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return const Color(0xFFB91C1C);
      case TransactionType.transfer:
        return const Color(0xFF475569);
      case TransactionType.income:
        return const Color(0xFF15803D);
      case TransactionType.adjustment:
        return const Color(0xFF0369A1);
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
        await widget.onAddTransaction(result.transactions.first);
      } else {
        await widget.onAddTransactions(result.transactions);
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
      await widget.onEditTransaction(result.transactions.first);
    }
  }

  Future<void> _showAddCategory(BuildContext context) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (result != null) {
      await widget.onAddCategory(result.category);
    }
  }

  Future<void> _showEditCategory(
      BuildContext context, Category category) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(initialCategory: category),
    );
    if (result != null) {
      await widget.onUpdateCategory(result.category);
    }
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

class _CollapsibleList extends StatelessWidget {
  const _CollapsibleList({
    required this.isExpanded,
    required this.collapsedLabel,
    required this.expandedLabel,
    required this.onToggle,
    required this.child,
  });

  final bool isExpanded;
  final String collapsedLabel;
  final String expandedLabel;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpanded ? expandedLabel : collapsedLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 10),
          child,
        ],
      ],
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

class _RecurringRuleTile extends StatelessWidget {
  const _RecurringRuleTile({
    required this.rule,
    required this.accountLabel,
    required this.categoryLabel,
    required this.onGenerate,
    required this.onDelete,
  });

  final RecurringTransactionRule rule;
  final String accountLabel;
  final String? categoryLabel;
  final VoidCallback onGenerate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).cardColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${_typeLabel(rule.type)} · ${_intervalLabel(rule.intervalMonths)} · $accountLabel'
                  '${categoryLabel == null ? '' : ' · $categoryLabel'}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(rule.amount, currency: rule.currency)} · 已生成 ${rule.generatedMonthKeys.length} 月',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onGenerate,
            child: const Text('生成'),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除周期规则',
          ),
        ],
      ),
    );
  }

  static String _typeLabel(TransactionType type) {
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

  static String _intervalLabel(int intervalMonths) {
    if (intervalMonths == 1) {
      return '每月';
    }
    if (intervalMonths == 3) {
      return '每季';
    }
    if (intervalMonths == 12) {
      return '每年';
    }
    return '每 $intervalMonths 个月';
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.accountLabel,
    required this.categoryLabel,
    required this.onUse,
    required this.onDelete,
  });

  final TransactionTemplate template;
  final String accountLabel;
  final String? categoryLabel;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onUse,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).cardColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _typeIcon(template.type),
              size: 16,
              color: _amountColor(template.type),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$accountLabel${categoryLabel == null ? '' : ' · $categoryLabel'}',
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDelete,
              icon: const Icon(Icons.close, size: 16),
              tooltip: '删除模板',
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.south_west_rounded;
      case TransactionType.expense:
        return Icons.north_east_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionType.adjustment:
        return Icons.tune_rounded;
    }
  }

  static Color _amountColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return const Color(0xFFB91C1C);
      case TransactionType.transfer:
        return const Color(0xFF475569);
      case TransactionType.income:
        return const Color(0xFF15803D);
      case TransactionType.adjustment:
        return const Color(0xFF0369A1);
    }
  }
}

class _TypeTotalChip extends StatelessWidget {
  const _TypeTotalChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).cardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            formatMoney(value),
            style:
                Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
