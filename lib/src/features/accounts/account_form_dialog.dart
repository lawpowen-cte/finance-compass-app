import 'package:flutter/material.dart';

import '../../core/models/account.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class AccountFormDialog extends StatefulWidget {
  const AccountFormDialog({
    super.key,
    this.initialAccount,
  });

  final Account? initialAccount;

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController institutionController;
  late final TextEditingController currencyController;
  late final TextEditingController initialBalanceController;
  late final TextEditingController currentBalanceController;
  late final TextEditingController noteController;

  late AccountType accountType;
  late ReportGroup reportGroup;

  bool get isEdit => widget.initialAccount != null;

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount;
    nameController = TextEditingController(text: account?.name ?? '');
    institutionController = TextEditingController(text: account?.institution ?? '');
    currencyController = TextEditingController(text: account?.currency ?? 'MYR');
    initialBalanceController = TextEditingController(
      text: (account?.initialBalance ?? 0).toStringAsFixed(2),
    );
    currentBalanceController = TextEditingController(
      text: (account?.currentBalance ?? account?.initialBalance ?? 0).toStringAsFixed(2),
    );
    noteController = TextEditingController(text: account?.note ?? '');
    accountType = account?.accountType ?? AccountType.cash;
    reportGroup = account?.reportGroup ?? ReportGroup.cash;
  }

  @override
  void dispose() {
    nameController.dispose();
    institutionController.dispose();
    currencyController.dispose();
    initialBalanceController.dispose();
    currentBalanceController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? '编辑账户' : '新增账户'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FinanceTextField(
                  controller: nameController,
                  label: '账户名称',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  initialValue: accountType,
                  decoration: const InputDecoration(
                    labelText: '账户类型',
                    border: OutlineInputBorder(),
                  ),
                  items: AccountType.values
                      .map((type) => DropdownMenuItem(value: type, child: Text(_accountTypeLabel(type))))
                      .toList(),
                  onChanged: (value) => setState(() {
                    accountType = value!;
                    reportGroup = _defaultReportGroupForType(value);
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportGroup>(
                  initialValue: reportGroup,
                  decoration: const InputDecoration(
                    labelText: '报表分组',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportGroup.values
                      .map((group) => DropdownMenuItem(value: group, child: Text(_groupLabel(group))))
                      .toList(),
                  onChanged: (value) => setState(() => reportGroup = value!),
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: currencyController,
                  label: '货币',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: initialBalanceController,
                  label: '初始余额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: currentBalanceController,
                  label: '当前余额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: institutionController,
                  label: '机构',
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: noteController,
                  label: '备注',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _submit() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final balance = double.parse(initialBalanceController.text.trim());
    final currentBalance = double.parse(currentBalanceController.text.trim());
    Navigator.of(context).pop(
      Account(
        id: widget.initialAccount?.id ?? buildId('acc'),
        name: nameController.text.trim(),
        accountType: accountType,
        reportGroup: reportGroup,
        currency: currencyController.text.trim().toUpperCase(),
        initialBalance: balance,
        currentBalance: currentBalance,
        institution: _nullIfEmpty(institutionController.text),
        note: _nullIfEmpty(noteController.text),
        isActive: widget.initialAccount?.isActive ?? true,
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? '必填' : null;
  String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? '请输入数字' : null;

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  String _groupLabel(ReportGroup group) {
    switch (group) {
      case ReportGroup.cash:
        return '现金';
      case ReportGroup.credit:
        return '信用';
      case ReportGroup.investment:
        return '投资';
      case ReportGroup.retirement:
        return '退休';
    }
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return '现金';
      case AccountType.bankSaving:
        return '储蓄户口';
      case AccountType.eWallet:
        return '电子钱包';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.moneyMarketFund:
        return '货币基金';
      case AccountType.pension:
        return '养老金';
      case AccountType.stock:
        return '股票';
      case AccountType.crypto:
        return '加密货币';
      case AccountType.trading:
        return '交易户口';
      case AccountType.fund:
        return '基金';
      case AccountType.other:
        return '其他';
    }
  }

  ReportGroup _defaultReportGroupForType(AccountType type) {
    switch (type) {
      case AccountType.cash:
      case AccountType.bankSaving:
      case AccountType.eWallet:
        return ReportGroup.cash;
      case AccountType.creditCard:
        return ReportGroup.credit;
      case AccountType.pension:
        return ReportGroup.retirement;
      case AccountType.moneyMarketFund:
      case AccountType.stock:
      case AccountType.crypto:
      case AccountType.trading:
      case AccountType.fund:
      case AccountType.other:
        return ReportGroup.investment;
    }
  }
}
