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
      title: Text(isEdit ? 'Edit Account' : 'Add Account'),
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
                  label: 'Account name',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AccountType>(
                  initialValue: accountType,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    border: OutlineInputBorder(),
                  ),
                  items: AccountType.values
                      .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
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
                    labelText: 'Report group',
                    border: OutlineInputBorder(),
                  ),
                  items: ReportGroup.values
                      .map((group) => DropdownMenuItem(value: group, child: Text(group.name)))
                      .toList(),
                  onChanged: (value) => setState(() => reportGroup = value!),
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: currencyController,
                  label: 'Currency',
                  validator: _required,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: initialBalanceController,
                  label: 'Initial balance',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: currentBalanceController,
                  label: 'Current balance',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: institutionController,
                  label: 'Institution',
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: noteController,
                  label: 'Note',
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
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

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;
  String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? 'Enter a number' : null;

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

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
