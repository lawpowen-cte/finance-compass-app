import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({
    super.key,
    required this.repository,
    this.initialTransaction,
  });

  final FinanceRepository repository;
  final FinanceTransaction? initialTransaction;

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final currencyController = TextEditingController(text: 'MYR');
  final descriptionController = TextEditingController();
  final merchantController = TextEditingController();

  TransactionType transactionType = TransactionType.expense;
  DateTime transactionDate = DateTime.now();
  String? accountId;
  String? toAccountId;
  String? categoryId;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.initialTransaction;
    if (initialTransaction != null) {
      transactionType = initialTransaction.type;
      transactionDate = initialTransaction.transactionDate;
      accountId = initialTransaction.accountId;
      toAccountId = initialTransaction.toAccountId;
      categoryId = initialTransaction.categoryId;
      amountController.text = initialTransaction.amount.toString();
      currencyController.text = initialTransaction.currency;
      descriptionController.text = initialTransaction.description ?? '';
      merchantController.text = initialTransaction.merchant ?? '';
      _syncCategoryDefault();
      return;
    }

    final accountOptions = _sortedAccounts();
    if (accountOptions.isNotEmpty) {
      accountId = _preferredAccountId(accountOptions);
    }
    _syncCategoryDefault();
  }

  @override
  void dispose() {
    amountController.dispose();
    currencyController.dispose();
    descriptionController.dispose();
    merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountOptions = _sortedAccounts();
    final categoryOptions = _categoryOptions();

    return AlertDialog(
      title: Text(widget.initialTransaction == null ? '新增交易' : '编辑交易'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
                  initialValue: transactionType,
                  decoration: const InputDecoration(
                    labelText: '交易类型',
                    border: OutlineInputBorder(),
                  ),
                  items: TransactionType.values
                      .map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(type))))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      transactionType = value;
                      toAccountId = null;
                      _syncCategoryDefault();
                    });
                  },
                ),
                if (transactionType == TransactionType.adjustment) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '用于记录投资或退休账户的新增投入，会同步影响余额、成本和现金余额。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: '转出账户',
                    border: OutlineInputBorder(),
                  ),
                  items: accountOptions
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text('${account.name} (${account.currency})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => accountId = value),
                ),
                if (transactionType == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: toAccountId,
                    decoration: const InputDecoration(
                      labelText: '转入账户',
                      border: OutlineInputBorder(),
                    ),
                    items: accountOptions
                        .where((account) => account.id != accountId)
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.name} (${account.currency})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => toAccountId = value),
                  ),
                ],
                if (categoryOptions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(
                      labelText: '类别',
                      border: OutlineInputBorder(),
                    ),
                    items: categoryOptions
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text('${category.name} (${_categoryTypeLabel(category.type)})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => categoryId = value),
                  ),
                ],
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: amountController,
                  label: '金额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: currencyController,
                  label: '货币',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('交易日期'),
                  subtitle: Text(
                    '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('修改'),
                  ),
                ),
                const SizedBox(height: 12),
                FinanceTextField(controller: descriptionController, label: '说明'),
                const SizedBox(height: 12),
                FinanceTextField(controller: merchantController, label: '商户'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  List<Account> _sortedAccounts() {
    final accounts = [...widget.repository.accounts]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return accounts;
  }

  List<Category> _categoryOptions() {
    final categories = switch (transactionType) {
      TransactionType.income => widget.repository.categoriesByType(CategoryType.income),
      TransactionType.expense => widget.repository.categoriesByType(CategoryType.expense),
      TransactionType.transfer => [
          ...widget.repository.categoriesByType(CategoryType.transfer),
          ...widget.repository.categoriesByType(CategoryType.investment),
        ],
      TransactionType.adjustment => [
          ...widget.repository.categoriesByType(CategoryType.investment),
          ...widget.repository.categoriesByType(CategoryType.transfer),
        ],
    };

    categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return categories;
  }

  String _preferredAccountId(List<Account> accounts) {
    final counts = <String, int>{};
    for (final transaction in widget.repository.transactions) {
      counts[transaction.accountId] = (counts[transaction.accountId] ?? 0) + 1;
    }

    accounts.sort((left, right) {
      final countCompare = (counts[right.id] ?? 0).compareTo(counts[left.id] ?? 0);
      if (countCompare != 0) {
        return countCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return accounts.first.id;
  }

  String? _preferredCategoryId(List<Category> categories) {
    if (categories.isEmpty) {
      return null;
    }

    final allowedCategoryIds = categories.map((item) => item.id).toSet();
    final counts = <String, int>{};
    for (final transaction in widget.repository.transactions) {
      if (transaction.type != transactionType) {
        continue;
      }
      final transactionCategoryId = transaction.categoryId;
      if (transactionCategoryId == null || !allowedCategoryIds.contains(transactionCategoryId)) {
        continue;
      }
      counts[transactionCategoryId] = (counts[transactionCategoryId] ?? 0) + 1;
    }

    categories.sort((left, right) {
      final countCompare = (counts[right.id] ?? 0).compareTo(counts[left.id] ?? 0);
      if (countCompare != 0) {
        return countCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return categories.first.id;
  }

  void _syncCategoryDefault() {
    final categories = _categoryOptions();
    if (categories.isEmpty) {
      categoryId = null;
      return;
    }
    if (categoryId != null && categories.any((item) => item.id == categoryId)) {
      return;
    }
    categoryId = _preferredCategoryId(categories);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => transactionDate = picked);
    }
  }

  void _submit() {
    if (!formKey.currentState!.validate() || accountId == null) {
      return;
    }
    if (transactionType == TransactionType.transfer && toAccountId == null) {
      return;
    }

    Navigator.of(context).pop(
      FinanceTransaction(
        id: widget.initialTransaction?.id ?? buildId('txn'),
        type: transactionType,
        accountId: accountId!,
        toAccountId: toAccountId,
        categoryId: categoryId,
        amount: double.parse(amountController.text.trim()),
        currency: currencyController.text.trim().toUpperCase(),
        transactionDate: transactionDate,
        description: _nullIfEmpty(descriptionController.text),
        merchant: _nullIfEmpty(merchantController.text),
      ),
    );
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

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? '必填' : null;

  String? _numberRequired(String? value) =>
      double.tryParse(value ?? '') == null ? '请输入数字' : null;

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();
}
