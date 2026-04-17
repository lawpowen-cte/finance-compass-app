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
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onAddCategory,
    required this.onUpdateCategory,
  });

  final FinanceRepository repository;
  final Future<void> Function(FinanceTransaction transaction) onAddTransaction;
  final Future<void> Function(FinanceTransaction transaction) onEditTransaction;
  final Future<void> Function(String transactionId) onDeleteTransaction;
  final Future<void> Function(Category category) onAddCategory;
  final Future<void> Function(Category category) onUpdateCategory;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? selectedCategoryId;
  String? selectedMonthKey;
  TransactionType? selectedTransactionType;
  bool showCategories = false;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final allCategories = repository.sortedCategories();
    final visibleCategories = _visibleCategories(allCategories);
    final effectiveCategoryId = visibleCategories.any((item) => item.id == selectedCategoryId)
        ? selectedCategoryId
        : null;
    final monthKeys = repository.transactions
        .map((item) => monthKeyFromDate(item.transactionDate))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final filteredTransactions = repository.transactions.where((transaction) {
      final matchesCategory =
          effectiveCategoryId == null || transaction.categoryId == effectiveCategoryId;
      final matchesMonth = selectedMonthKey == null ||
          monthKeyFromDate(transaction.transactionDate) == selectedMonthKey;
      final matchesType =
          selectedTransactionType == null || transaction.type == selectedTransactionType;
      return matchesCategory && matchesMonth && matchesType;
    });
    final transactions = [...filteredTransactions]
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length + 2,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: '交易',
                actions: [
                  IconButton.filledTonal(
                    onPressed: () => _showAddCategory(context),
                    icon: const Icon(Icons.category),
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
            ],
          );
        }

        if (index == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: selectedMonthKey,
                      decoration: const InputDecoration(
                        labelText: '月份',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('全部月份'),
                        ),
                        ...monthKeys.map(
                          (monthKey) => DropdownMenuItem<String?>(
                            value: monthKey,
                            child: Text(monthLabel(monthKey)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedMonthKey = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TransactionType?>(
                      initialValue: selectedTransactionType,
                      decoration: const InputDecoration(
                        labelText: '类型',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<TransactionType?>(
                          value: null,
                          child: Text('全部类型'),
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
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('全部类别'),
                        ),
                        ...visibleCategories.map(
                          (category) => DropdownMenuItem<String?>(
                            value: category.id,
                            child: Text('${category.name}（${_categoryTypeLabel(category.type)}）'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedCategoryId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                            Expanded(
                              child: Text(showCategories ? '收起类别' : '展开类别'),
                            ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context).cardColor.withValues(alpha: 0.7),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(category.name),
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
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        final transaction = transactions[index - 2];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(transaction.description ?? transaction.merchant ?? _typeLabel(transaction.type)),
          subtitle: Text(
            '${_typeLabel(transaction.type)} • ${repository.accountName(transaction.accountId)} • '
            '${transaction.transactionDate.year}-${transaction.transactionDate.month.toString().padLeft(2, '0')}-${transaction.transactionDate.day.toString().padLeft(2, '0')}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _displayAmount(transaction),
                style: TextStyle(
                  color: transaction.type == TransactionType.expense ? Colors.red : Colors.green,
                ),
              ),
              PopupMenuButton<String>(
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
        );
      },
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

  String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '收入';
      case TransactionType.expense:
        return '支出';
      case TransactionType.transfer:
        return '转账';
      case TransactionType.adjustment:
        return '调整';
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
    final result = await showDialog<FinanceTransaction>(
      context: context,
      builder: (_) => TransactionFormDialog(repository: widget.repository),
    );
    if (result != null) {
      await widget.onAddTransaction(result);
    }
  }

  Future<void> _showEditTransaction(BuildContext context, FinanceTransaction transaction) async {
    final result = await showDialog<FinanceTransaction>(
      context: context,
      builder: (_) => TransactionFormDialog(
        repository: widget.repository,
        initialTransaction: transaction,
      ),
    );
    if (result != null) {
      await widget.onEditTransaction(result);
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
