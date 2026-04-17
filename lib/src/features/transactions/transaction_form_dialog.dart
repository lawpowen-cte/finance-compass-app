import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
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
    } else if (widget.repository.accounts.isNotEmpty) {
      accountId = widget.repository.accounts.first.id;
      _syncCategoryDefault();
    }
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
    final categoryOptions = _categoryOptions();
    final accountOptions = widget.repository.accounts;

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
                  onChanged: (value) => setState(() {
                    transactionType = value!;
                    toAccountId = null;
                    _syncCategoryDefault();
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: '转出账户',
                    border: OutlineInputBorder(),
                  ),
                  items: accountOptions
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.name} (${account.currency})'),
                          ))
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
                        .map((account) => DropdownMenuItem(
                              value: account.id,
                              child: Text('${account.name} (${account.currency})'),
                            ))
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
                        .map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Text('${category.name} (${_categoryTypeLabel(category.type)})'),
                            ))
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

  List<Category> _categoryOptions() {
    switch (transactionType) {
      case TransactionType.income:
        return widget.repository.categoriesByType(CategoryType.income);
      case TransactionType.expense:
        return widget.repository.categoriesByType(CategoryType.expense);
      case TransactionType.transfer:
        return [
          ...widget.repository.categoriesByType(CategoryType.transfer),
          ...widget.repository.categoriesByType(CategoryType.investment),
        ];
      case TransactionType.adjustment:
        return [
          ...widget.repository.categoriesByType(CategoryType.investment),
          ...widget.repository.categoriesByType(CategoryType.transfer),
        ];
    }
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
    categoryId = categories.first.id;
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

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? '必填' : null;
  String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? '请输入数字' : null;
  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();
}
