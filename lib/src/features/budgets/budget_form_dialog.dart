import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/budget.dart';
import '../../core/models/category.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/month_key.dart';
import '../shared/finance_form_fields.dart';

class BudgetFormDialog extends StatefulWidget {
  const BudgetFormDialog({
    super.key,
    required this.repository,
    this.initialBudget,
  });

  final FinanceRepository repository;
  final Budget? initialBudget;

  @override
  State<BudgetFormDialog> createState() => _BudgetFormDialogState();
}

class _BudgetFormDialogState extends State<BudgetFormDialog> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final thresholdController = TextEditingController(text: '0.8');
  final monthController = TextEditingController(text: monthKeyFromDate(DateTime.now()));

  late List<Category> categories;
  String? categoryId;
  bool rolloverEnabled = false;

  @override
  void initState() {
    super.initState();
    categories = widget.repository.categoriesByType(CategoryType.expense);
    final initialBudget = widget.initialBudget;
    if (initialBudget != null) {
      categoryId = initialBudget.categoryId;
      amountController.text = initialBudget.amount.toString();
      thresholdController.text = initialBudget.alertThreshold.toString();
      monthController.text = initialBudget.monthKey;
      rolloverEnabled = initialBudget.rolloverEnabled;
    } else if (categories.isNotEmpty) {
      categoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    thresholdController.dispose();
    monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialBudget == null ? '新增预算' : '编辑预算'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(
                    labelText: '支出类别',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => categoryId = value),
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: monthController,
                  label: '设立月份',
                  validator: (value) => RegExp(r'^\d{4}-\d{2}$').hasMatch(value ?? '')
                      ? null
                      : '格式 YYYY-MM',
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: amountController,
                  label: '预算金额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: thresholdController,
                  label: '提醒阈值',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: rolloverEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用结转'),
                  onChanged: (value) => setState(() => rolloverEnabled = value),
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

  void _submit() {
    if (!formKey.currentState!.validate() || categoryId == null) {
      return;
    }

    Navigator.of(context).pop(
      Budget(
        id: widget.initialBudget?.id ?? buildId('budget'),
        categoryId: categoryId!,
        monthKey: monthController.text.trim(),
        amount: double.parse(amountController.text.trim()),
        alertThreshold: double.parse(thresholdController.text.trim()),
        rolloverEnabled: rolloverEnabled,
      ),
    );
  }

  String? _numberRequired(String? value) => double.tryParse(value ?? '') == null ? '请输入数字' : null;
}
