import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/account.dart';
import '../../core/models/category.dart';
import '../../core/models/transaction.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({
    super.key,
    required this.repository,
    this.initialTransaction,
    this.draftTransaction,
  });

  final FinanceRepository repository;
  final FinanceTransaction? initialTransaction;
  final FinanceTransaction? draftTransaction;

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final toAmountController = TextEditingController();
  final descriptionController = TextEditingController();
  final merchantController = TextEditingController();

  TransactionType transactionType = TransactionType.expense;
  TransactionStatus transactionStatus = TransactionStatus.actual;
  String currency = 'MYR';
  String toCurrency = 'MYR';
  DateTime recordDate = DateTime.now();
  DateTime? settlementDate;
  String? accountId;
  String? toAccountId;
  String? categoryId;
  int recurrenceMonths = 1;
  bool _isAutoSettingToAmount = false;
  bool _toAmountEditedByUser = false;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.initialTransaction;
    final draftTransaction = widget.draftTransaction;
    final seedTransaction = initialTransaction ?? draftTransaction;
    if (seedTransaction != null) {
      transactionType = seedTransaction.type;
      transactionStatus = seedTransaction.status == TransactionStatus.settled
          ? TransactionStatus.actual
          : seedTransaction.status;
      recordDate = initialTransaction == null
          ? DateTime.now()
          : seedTransaction.recordDate;
      settlementDate =
          initialTransaction == null ? null : seedTransaction.transactionDate;
      accountId = seedTransaction.accountId;
      toAccountId = seedTransaction.toAccountId;
      categoryId = seedTransaction.categoryId;
      amountController.text = seedTransaction.amount.toString();
      currency = normalizeCurrency(seedTransaction.currency);
      toAmountController.text = seedTransaction.toAmount?.toString() ?? '';
      toCurrency = normalizeCurrency(
        seedTransaction.toCurrency ?? seedTransaction.transferInCurrency,
      );
      _toAmountEditedByUser = seedTransaction.toAmount != null;
      descriptionController.text = seedTransaction.description ?? '';
      merchantController.text = seedTransaction.merchant ?? '';
      _syncCategoryDefault();
    }

    final accountOptions = _sortedAccounts();
    if (accountOptions.isNotEmpty && accountId == null) {
      accountId = _preferredAccountId(accountOptions);
      currency = _currencyForAccount(accountId!) ?? currency;
    }
    if (accountId != null) {
      currency = _currencyForAccount(accountId!) ?? currency;
    }
    if (toAccountId != null) {
      toCurrency = _currencyForAccount(toAccountId!) ?? toCurrency;
    }
    _syncCategoryDefault();
    amountController.addListener(_updateTransferEstimateIfAllowed);
    toAmountController.addListener(_markToAmountEdited);
    _updateTransferEstimate(force: toAmountController.text.trim().isEmpty);
  }

  @override
  void dispose() {
    amountController.dispose();
    toAmountController.dispose();
    descriptionController.dispose();
    merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountOptions = _sortedAccounts();
    final categoryOptions = _categoryOptions();

    return AlertDialog(
      title: Text(_isEditing ? '编辑交易' : '新增交易'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TransactionType>(
                  value: transactionType,
                  decoration: const InputDecoration(
                    labelText: '交易类型',
                    border: OutlineInputBorder(),
                  ),
                  items: TransactionType.values
                      .map((type) => DropdownMenuItem(
                          value: type, child: Text(_typeLabel(type))))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      transactionType = value;
                      toAccountId = null;
                      _toAmountEditedByUser = false;
                      _syncCategoryDefault();
                    });
                    _updateTransferEstimate(force: true);
                  },
                ),
                const SizedBox(height: 12),
                _StatusSwitch(
                  value: transactionStatus,
                  plannedLabel: _statusLabel(TransactionStatus.planned),
                  actualLabel: _statusLabel(TransactionStatus.actual),
                  onChanged: (value) =>
                      setState(() => transactionStatus = value),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '预计不会影响账户真实余额；已发生会计入账户。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
                  value: accountId,
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
                  onChanged: (value) => setState(() {
                    accountId = value;
                    if (value != null) {
                      currency = _currencyForAccount(value) ?? currency;
                    }
                    _toAmountEditedByUser = false;
                    _updateTransferEstimate(force: true);
                  }),
                ),
                if (transactionType == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: toAccountId,
                    decoration: const InputDecoration(
                      labelText: '转入账户',
                      border: OutlineInputBorder(),
                    ),
                    items: accountOptions
                        .where((account) => account.id != accountId)
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child:
                                Text('${account.name} (${account.currency})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      toAccountId = value;
                      if (value != null) {
                        toCurrency = _currencyForAccount(value) ?? toCurrency;
                      }
                      _toAmountEditedByUser = false;
                      _updateTransferEstimate(force: true);
                    }),
                  ),
                ],
                if (categoryOptions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: '类别',
                      border: OutlineInputBorder(),
                    ),
                    items: categoryOptions
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(
                                '${category.name} (${_categoryTypeLabel(category.type)})'),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                _CurrencyDisplayField(
                  label: '货币',
                  currency: currency,
                  helperText: '跟随转出账户',
                ),
                if (transactionType == TransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  FinanceTextField(
                    controller: toAmountController,
                    label: '转入金额',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberRequired,
                  ),
                  const SizedBox(height: 12),
                  _CurrencyDisplayField(
                    label: '转入币种',
                    currency: toCurrency,
                    helperText: '跟随转入账户',
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _transferPreviewText(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _DateTile(
                  title: '记录日期',
                  value: recordDate,
                  onPick: () => _pickRecordDate(),
                ),
                const SizedBox(height: 8),
                _DateTile(
                  title: '结算日期',
                  value: settlementDate,
                  emptyLabel: '未填写时使用记录日期',
                  onPick: () => _pickSettlementDate(),
                  onClear: settlementDate == null
                      ? null
                      : () => setState(() => settlementDate = null),
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: recurrenceMonths,
                    decoration: const InputDecoration(
                      labelText: '生成周期',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1} 个月'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => recurrenceMonths = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '会从当前日期开始，按月生成未来 $recurrenceMonths 个月的记录，包含当前这笔。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FinanceTextField(
                    controller: descriptionController, label: '说明'),
                const SizedBox(height: 12),
                FinanceTextField(controller: merchantController, label: '商户'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消')),
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
      TransactionType.income =>
        widget.repository.categoriesByType(CategoryType.income),
      TransactionType.expense =>
        widget.repository.categoriesByType(CategoryType.expense),
      TransactionType.transfer => [
          ...widget.repository.categoriesByType(CategoryType.transfer),
          ...widget.repository.categoriesByType(CategoryType.investment),
        ],
      TransactionType.adjustment => [
          ...widget.repository.categoriesByType(CategoryType.investment),
          ...widget.repository.categoriesByType(CategoryType.transfer),
        ],
    };

    categories
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return categories;
  }

  String _preferredAccountId(List<Account> accounts) {
    final counts = <String, int>{};
    for (final transaction in widget.repository.transactions) {
      counts[transaction.accountId] = (counts[transaction.accountId] ?? 0) + 1;
    }

    accounts.sort((left, right) {
      final countCompare =
          (counts[right.id] ?? 0).compareTo(counts[left.id] ?? 0);
      if (countCompare != 0) {
        return countCompare;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return accounts.first.id;
  }

  String? _currencyForAccount(String accountId) {
    for (final account in widget.repository.accounts) {
      if (account.id == accountId) {
        return normalizeCurrency(account.currency);
      }
    }
    return null;
  }

  void _markToAmountEdited() {
    if (_isAutoSettingToAmount) {
      return;
    }
    _toAmountEditedByUser = true;
  }

  void _updateTransferEstimateIfAllowed() {
    _updateTransferEstimate();
  }

  void _updateTransferEstimate({bool force = false}) {
    if (transactionType != TransactionType.transfer) {
      return;
    }
    if (!force && _toAmountEditedByUser) {
      return;
    }
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) {
      return;
    }
    final estimate = widget.repository.convertAmount(
      amount: amount,
      fromCurrency: currency,
      toCurrency: toCurrency,
    );
    _isAutoSettingToAmount = true;
    toAmountController.text = estimate.toStringAsFixed(2);
    _isAutoSettingToAmount = false;
  }

  String _transferPreviewText() {
    final amount = double.tryParse(amountController.text.trim());
    final toAmount = double.tryParse(toAmountController.text.trim());
    if (amount == null || toAmount == null) {
      return '转账会按转出账户扣款，并按转入金额写入目标账户。';
    }
    return '${formatMoney(amount, currency: currency)} → '
        '${formatMoney(toAmount, currency: toCurrency)}';
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
      if (transactionCategoryId == null ||
          !allowedCategoryIds.contains(transactionCategoryId)) {
        continue;
      }
      counts[transactionCategoryId] = (counts[transactionCategoryId] ?? 0) + 1;
    }

    categories.sort((left, right) {
      final countCompare =
          (counts[right.id] ?? 0).compareTo(counts[left.id] ?? 0);
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

  Future<void> _pickRecordDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => recordDate = picked);
    }
  }

  Future<void> _pickSettlementDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: settlementDate ?? recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => settlementDate = picked);
    }
  }

  void _submit() {
    if (!formKey.currentState!.validate() || accountId == null) {
      return;
    }
    if (transactionType == TransactionType.transfer && toAccountId == null) {
      return;
    }

    final amount = double.parse(amountController.text.trim());
    final transferInAmount = transactionType == TransactionType.transfer
        ? double.parse(toAmountController.text.trim())
        : null;
    final transferInCurrency = transactionType == TransactionType.transfer
        ? normalizeCurrency(toCurrency)
        : null;
    final description = _nullIfEmpty(descriptionController.text);
    final merchant = _nullIfEmpty(merchantController.text);
    final effectiveSettlementDate = settlementDate ?? recordDate;

    if (_isEditing) {
      Navigator.of(context).pop(
        TransactionFormResult(
          transactions: [
            FinanceTransaction(
              id: widget.initialTransaction!.id,
              type: transactionType,
              accountId: accountId!,
              toAccountId: toAccountId,
              categoryId: categoryId,
              amount: amount,
              currency: currency,
              toAmount: transferInAmount,
              toCurrency: transferInCurrency,
              recordDate: recordDate,
              transactionDate: effectiveSettlementDate,
              status: transactionStatus,
              recurringRuleId: widget.initialTransaction!.recurringRuleId,
              description: description,
              merchant: merchant,
            ),
          ],
        ),
      );
      return;
    }

    final transactions = buildRecurringTransactions(
      months: recurrenceMonths,
      baseTransaction: FinanceTransaction(
        id: buildId('txn'),
        type: transactionType,
        accountId: accountId!,
        toAccountId: toAccountId,
        categoryId: categoryId,
        amount: amount,
        currency: currency,
        toAmount: transferInAmount,
        toCurrency: transferInCurrency,
        recordDate: recordDate,
        transactionDate: effectiveSettlementDate,
        status: transactionStatus,
        description: description,
        merchant: merchant,
      ),
    );

    Navigator.of(context)
        .pop(TransactionFormResult(transactions: transactions));
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

  String? _numberRequired(String? value) =>
      double.tryParse(value ?? '') == null ? '请输入数字' : null;

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.title,
    required this.value,
    required this.onPick,
    this.emptyLabel,
    this.onClear,
  });

  final String title;
  final DateTime? value;
  final String? emptyLabel;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value == null ? emptyLabel ?? '未填写' : _formatDate(value!)),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              tooltip: '清空',
            ),
          TextButton(
            onPressed: onPick,
            child: const Text('修改'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _CurrencyDisplayField extends StatelessWidget {
  const _CurrencyDisplayField({
    required this.label,
    required this.currency,
    required this.helperText,
  });

  final String label;
  final String currency;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      child: Text(currencyOptionLabel(currency)),
    );
  }
}

class TransactionFormResult {
  const TransactionFormResult({
    required this.transactions,
  });

  final List<FinanceTransaction> transactions;
}

class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({
    required this.value,
    required this.plannedLabel,
    required this.actualLabel,
    required this.onChanged,
  });

  final TransactionStatus value;
  final String plannedLabel;
  final String actualLabel;
  final ValueChanged<TransactionStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.outline.withValues(alpha: 0.55);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: '状态',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusSwitchOption(
              label: plannedLabel,
              selected: value == TransactionStatus.planned,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(7),
              ),
              borderColor: borderColor,
              onTap: () => onChanged(TransactionStatus.planned),
            ),
          ),
          Expanded(
            child: _StatusSwitchOption(
              label: actualLabel,
              selected: value != TransactionStatus.planned,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(7),
              ),
              borderColor: borderColor,
              onTap: () => onChanged(TransactionStatus.actual),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSwitchOption extends StatelessWidget {
  const _StatusSwitchOption({
    required this.label,
    required this.selected,
    required this.borderRadius,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final BorderRadius borderRadius;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: selected ? colorScheme.primary : borderColor,
              width: selected ? 1.4 : 0.8,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

List<FinanceTransaction> buildRecurringTransactions({
  required FinanceTransaction baseTransaction,
  required int months,
}) {
  final safeMonths = months < 1 ? 1 : months;
  final idPrefix = baseTransaction.id;

  return List.generate(safeMonths, (index) {
    final settlementDate = DateTime(
      baseTransaction.transactionDate.year,
      baseTransaction.transactionDate.month + index,
      baseTransaction.transactionDate.day,
    );
    final recordDate = DateTime(
      baseTransaction.recordDate.year,
      baseTransaction.recordDate.month + index,
      baseTransaction.recordDate.day,
    );
    return FinanceTransaction(
      id: '$idPrefix-${index + 1}',
      type: baseTransaction.type,
      accountId: baseTransaction.accountId,
      toAccountId: baseTransaction.toAccountId,
      categoryId: baseTransaction.categoryId,
      amount: baseTransaction.amount,
      currency: baseTransaction.currency,
      toAmount: baseTransaction.toAmount,
      toCurrency: baseTransaction.toCurrency,
      recordDate: recordDate,
      transactionDate: settlementDate,
      status: index == 0 ? baseTransaction.status : TransactionStatus.planned,
      recurringRuleId: baseTransaction.recurringRuleId,
      description: baseTransaction.description,
      merchant: baseTransaction.merchant,
    );
  });
}
