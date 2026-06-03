import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/providers/mutations/category_mutations.dart';
import '../../core/providers/mutations/transaction_mutations.dart';

import '../../core/utils/currency_formatter.dart';
import '../../core/utils/month_key.dart';
import '../../core/utils/month_range.dart';
import '../categories/category_form_dialog.dart';
import '../shared/screen_header.dart';
import '../shared/section_card.dart';
import 'transaction_form_dialog.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.repository,
  });

  final FinanceRepository repository;

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? selectedCategoryId;
  String? selectedAccountId;
  String? selectedMonthFrom = monthKeyFromDate(DateTime.now());
  String? selectedMonthTo = monthKeyFromDate(DateTime.now());
  TransactionType? selectedTransactionType;
  TransactionStatus? selectedTransactionStatus;
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
    final actualTransactions = filteredTransactions
        .where((item) => item.status != TransactionStatus.planned);
    final actualIncome = actualTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final actualExpense = actualTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final actualAdjustment = actualTransactions
        .where((item) => item.type == TransactionType.adjustment)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final netCashFlow = actualIncome - actualExpense;

    final allIncome = filteredTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final allExpense = filteredTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final allAdjustment = filteredTransactions
        .where((item) => item.type == TransactionType.adjustment)
        .fold<double>(0, (sum, item) => sum + repository.transactionAmountInBase(item));
    final netAssetChange = allIncome - allExpense + allAdjustment;

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
          title: '快速模板 & 周期交易',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (templates.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: templates.map((template) {
                    return _TemplateChip(
                      template: template,
                      onTap: () => _showAddTransaction(
                        context,
                        draftTransaction: _draftFromTemplate(template),
                      ),
                      onLongPress: () =>
                          _showTemplateActions(context, template),
                    );
                  }).toList(),
                )
              else
                const Text('暂无模板',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              if (templates.isNotEmpty && recurringRules.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
              if (recurringRules.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recurringRules.map((rule) {
                    return _RecurringRuleChip(
                      rule: rule,
                      onTap: () =>
                          _generateRecurringTransactions(context, rule),
                      onLongPress: () =>
                          _showRecurringRuleActions(context, rule),
                    );
                  }).toList(),
                )
              else if (templates.isEmpty)
                const Text('暂无周期规则',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
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
                label: '净现金流',
                value: netCashFlow,
                color: netCashFlow >= 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
              _TypeTotalChip(
                label: '净现金流（含预计）',
                value: netAssetChange,
                color: netAssetChange >= 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
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
                    final categoryName = transaction.categoryId == null
                        ? null
                        : _categoryNameOrFallback(
                            repository, transaction.categoryId!);
                    final hint =
                        _displayConversionHint(repository, transaction);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).cardColor,
                        border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                        color: _amountColor(
                                            transaction.type),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _typeLabel(transaction.type),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: _amountColor(
                                            transaction.type),
                                      ),
                                    ),
                                  ],
                                ),
                                if (hint.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 1),
                                    child: Text(hint,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(fontSize: 10)),
                                  ),
                                if (_isMeaningfulDescription(transaction))
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 1),
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
                                    _MetaChip(
                                        label: repository.accountName(
                                            transaction.accountId)),
                                    if (categoryName != null)
                                      _MetaChip(label: categoryName),
                                    if (transaction.status ==
                                        TransactionStatus.planned)
                                      const _PlannedChip(),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                                icon: Icon(Icons.more_horiz,
                                    size: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                                onSelected: (value) =>
                                    _handleTransactionAction(
                                  context,
                                  value,
                                  transaction,
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('编辑')),
                                  PopupMenuItem(
                                      value: 'reuse',
                                      child: Text('复用新增')),
                                  PopupMenuItem(
                                      value: 'template',
                                      child: Text('保存模板')),
                                  PopupMenuItem(
                                      value: 'recurring',
                                      child: Text('保存周期')),
                                  PopupMenuDivider(),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('删除')),
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

  Future<void> _deleteCategory(
      BuildContext context, Category category) async {
    final deleted = await ref
        .read(categoryMutationsProvider.notifier)
        .deleteCategory(category.id);
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
    await ref.read(transactionMutationsProvider.notifier).addTransactionTemplate(
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

  Future<void> _showAddCategory(BuildContext context) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (result != null) {
      await ref
          .read(categoryMutationsProvider.notifier)
          .addCategory(result.category);
    }
  }

  Future<void> _showEditCategory(
      BuildContext context, Category category) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(initialCategory: category),
    );
    if (result != null) {
      await ref
          .read(categoryMutationsProvider.notifier)
          .updateCategory(result.category);
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

class _RecurringRuleChip extends StatelessWidget {
  const _RecurringRuleChip({
    required this.rule,
    required this.onTap,
    required this.onLongPress,
  });

  final RecurringTransactionRule rule;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(width: 4),
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
  });

  final TransactionTemplate template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(width: 4),
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
          ],
        ),
      ),
    );
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.8),
            ),
      ),
    );
  }
}

class _PlannedChip extends StatelessWidget {
  const _PlannedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFB45309).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '预计',
        style: TextStyle(
          fontSize: 10,
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
