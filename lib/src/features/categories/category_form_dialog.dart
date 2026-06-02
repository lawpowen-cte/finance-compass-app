import 'package:flutter/material.dart';

import '../../core/models/category.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class CategoryFormResult {
  const CategoryFormResult({
    required this.category,
    required this.isEdit,
  });

  final Category category;
  final bool isEdit;
}

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    this.initialCategory,
  });

  final Category? initialCategory;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController parentIdController;
  late CategoryType categoryType;

  bool get isEdit => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialCategory?.name ?? '');
    parentIdController = TextEditingController(text: widget.initialCategory?.parentId ?? '');
    categoryType = widget.initialCategory?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    nameController.dispose();
    parentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? '编辑类别' : '新增类别'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinanceTextField(
                controller: nameController,
                label: '类别名称',
                validator: (value) => (value == null || value.trim().isEmpty) ? '必填' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CategoryType>(
                value: categoryType,
                decoration: const InputDecoration(
                  labelText: '类别类型',
                  border: OutlineInputBorder(),
                ),
                items: CategoryType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(_typeLabel(type))))
                    .toList(),
                onChanged: (value) => setState(() => categoryType = value!),
              ),
              const SizedBox(height: 12),
              FinanceTextField(
                controller: parentIdController,
                label: '父类别 ID（可选）',
              ),
            ],
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

    final category = Category(
      id: widget.initialCategory?.id ?? buildId('cat'),
      name: nameController.text.trim(),
      type: categoryType,
      parentId: parentIdController.text.trim().isEmpty ? null : parentIdController.text.trim(),
    );

    Navigator.of(context).pop(
      CategoryFormResult(category: category, isEdit: isEdit),
    );
  }

  String _typeLabel(CategoryType type) {
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
}
