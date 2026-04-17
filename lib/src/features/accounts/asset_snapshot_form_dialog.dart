import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class AssetSnapshotFormDialog extends StatefulWidget {
  const AssetSnapshotFormDialog({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<AssetSnapshotFormDialog> createState() => _AssetSnapshotFormDialogState();
}

class _AssetSnapshotFormDialogState extends State<AssetSnapshotFormDialog> {
  final formKey = GlobalKey<FormState>();
  final marketValueController = TextEditingController();
  final costBasisController = TextEditingController(text: '0');
  final cashBalanceController = TextEditingController(text: '0');
  final pnlController = TextEditingController(text: '0');

  DateTime snapshotDate = DateTime.now();
  String? accountId;

  @override
  void initState() {
    super.initState();
    final investments = widget.repository.investmentAccounts();
    if (investments.isNotEmpty) {
      accountId = investments.first.id;
    }
  }

  @override
  void dispose() {
    marketValueController.dispose();
    costBasisController.dispose();
    cashBalanceController.dispose();
    pnlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investments = widget.repository.investmentAccounts();
    return AlertDialog(
      title: const Text('新增资产快照'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: '投资账户',
                    border: OutlineInputBorder(),
                  ),
                  items: investments
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => accountId = value),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('快照日期'),
                  subtitle: Text(
                    '${snapshotDate.year}-${snapshotDate.month.toString().padLeft(2, '0')}-${snapshotDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('修改'),
                  ),
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: marketValueController,
                  label: '市值',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: costBasisController,
                  label: '成本',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: cashBalanceController,
                  label: '现金余额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: pnlController,
                  label: '未实现盈亏',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: snapshotDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => snapshotDate = picked);
    }
  }

  void _submit() {
    if (!formKey.currentState!.validate() || accountId == null) {
      return;
    }

    Navigator.of(context).pop(
      AssetSnapshot(
        id: buildId('snap'),
        accountId: accountId!,
        snapshotDate: snapshotDate,
        marketValue: double.parse(marketValueController.text.trim()),
        costBasis: double.parse(costBasisController.text.trim()),
        cashBalance: double.parse(cashBalanceController.text.trim()),
        unrealizedPnl: double.parse(pnlController.text.trim()),
      ),
    );
  }

  String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? '请输入数字' : null;
}
