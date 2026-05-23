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
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  final FinanceRepository repository;
  final Future<void> Function(FinanceTransaction transaction) onAddTransaction;
  final Future<void> Function(List<FinanceTransaction> transactions) onAddTransactions;
  final Future<void> Function(FinanceTransaction transaction) onEditTransaction;
  final Future<void> Function(String transactionId) onDeleteTransaction;
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
  bool showCategories = false;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final allCategories = [...repository.sortedCategories()]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final visibleCategories = _visibleCategories(allCategories);
    final effectiveCategoryId = visibleCategories.any((item) => item.id == selectedCategoryId)
        ? selectedCategoryId
        : null;
    final accounts = [...repository.accounts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final effectiveAccountId =
        accounts.any((item) => item.id == selectedAccountId) ? selectedAccountId : null;
    final monthKeys = {
      monthKeyFromDate(DateTime.now()),
      ...repository.transactions.map((item) => monthKeyFromDate(item.transactionDate)),
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
      final matchesCategory =
          effectiveCategoryId == null || transaction.categoryId == effectiveCategoryId;
      final matchesAccount = effectiveAccountId == null ||
          transaction.accountId == effectiveAccountId ||
          transaction.toAccountId == effectiveAccountId;
      final matchesMonthFrom =
          selectedMonthFrom == null || transactionMonthKey.compareTo(selectedMonthFrom!) >= 0;
      final matchesMonthTo =
          selectedMonthTo == null || transactionMonthKey.compareTo(selectedMonthTo!) <= 0;
      final matchesType =
          selectedTransactionType == null || transaction.type == selectedTransactionType;
      return matchesCategory &&
          matchesAccount &&
          matchesMonthFrom &&
          matchesMonthTo &&
          matchesType;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final totalsByType = <TransactionType, double>{
      for (final type in TransactionType.values) type: 0,
    };
    for (final transaction in filteredTransactions) {
      totalsByType[transaction.type] = (totalsByType[transaction.type] ?? 0) + transaction.amount;
    }

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
          title: '筛选',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
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
                            child: Text(monthLabel(monthKey)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        selectedMonthFrom = value;
                        if (selectedMonthFrom != null &&
                            selectedMonthTo != null &&
                            selectedMonthFrom!.compareTo(selectedMonthTo!) > 0) {
                          selectedMonthTo = selectedMonthFrom;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
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
                            child: Text(monthLabel(monthKey)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        selectedMonthTo = value;
                        if (selectedMonthFrom != null &&
                            selectedMonthTo != null &&
                            selectedMonthFrom!.compareTo(selectedMonthTo!) > 0) {
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
                            child: Text(account.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedAccountId = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TransactionType?>(
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
                            child: Text(_typeLabel(type)),
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
                            child: Text('${category.name} · ${_categoryTypeLabel(category.type)}'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedCategoryId = value),
                    ),
                  ),
                ],
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
                      Icon(showCategories ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (showCategories) ...[
                const SizedBox(height: 12),
                ...visibleCategories.map((category) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).cardColor.withValues(alpha: 0.86),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).cardColor.withValues(alpha: 0.86),
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
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditTransaction(context, transaction);
                                  }
                                  if (value == 'delete') {
                                    widget.onDeleteTransaction(transaction.id);
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
        return categories.where((item) => item.type == CategoryType.income).toList();
      case TransactionType.expense:
        return categories.where((item) => item.type == CategoryType.expense).toList();
      case TransactionType.transfer:
      case TransactionType.adjustment:
        return categories
            .where((item) => item.type == CategoryType.transfer || item.type == CategoryType.investment)
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

  String _transactionMeta(FinanceRepository repository, FinanceTransaction transaction) {
    final categoryName =
        transaction.categoryId == null ? null : repository.categoryName(transaction.categoryId!);
    final dateLabel =
        '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}';
    return [
      _typeLabel(transaction.type),
      repository.accountName(transaction.accountId),
      if (categoryName != null) categoryName,
      dateLabel,
    ].join(' · ');
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

  Future<void> _showAddTransaction(BuildContext context) async {
    final result = await showDialog<TransactionFormResult>(
      context: context,
      builder: (_) => TransactionFormDialog(repository: widget.repository),
    );
    if (result != null) {
      if (result.transactions.length == 1) {
        await widget.onAddTransaction(result.transactions.first);
      } else {
        await widget.onAddTransactions(result.transactions);
      }
    }
  }

  Future<void> _showEditTransaction(BuildContext context, FinanceTransaction transaction) async {
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

  Future<void> _showEditCategory(BuildContext context, Category category) async {
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
        return formatMoney(transaction.amount, currency: transaction.currency);
      case TransactionType.income:
      case TransactionType.adjustment:
        return '+${formatMoney(transaction.amount, currency: transaction.currency)}';
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
