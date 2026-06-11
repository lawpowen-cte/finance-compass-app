import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/category.dart';
import '../../core/providers/mutations/category_mutations.dart';
import '../shared/finance_action_menu_button.dart';
import 'category_form_dialog.dart';

class CategoryManageScreen extends ConsumerStatefulWidget {
  const CategoryManageScreen({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  ConsumerState<CategoryManageScreen> createState() =>
      _CategoryManageScreenState();
}

class _CategoryManageScreenState extends ConsumerState<CategoryManageScreen> {
  String _searchQuery = '';
  CategoryType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final allCategories = [...repository.sortedCategories()]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final filteredCategories = allCategories.where((category) {
      final matchesSearch = _searchQuery.isEmpty ||
          category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _selectedType == null || category.type == _selectedType;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('类别管理'),
        actions: [
          IconButton.filled(
            onPressed: () => _showAddCategory(context),
            icon: const Icon(Icons.add),
            tooltip: '新增类别',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: '搜索类别',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('全部'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              ...CategoryType.values.map(
                (type) => FilterChip(
                  label: Text(_categoryTypeLabel(type)),
                  selected: _selectedType == type,
                  onSelected: (_) => setState(() => _selectedType = type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('暂无类别'),
              ),
            )
          else
            ...filteredCategories.map(
              (category) => _CategoryTile(
                category: category,
                repository: repository,
                onEdit: () => _showEditCategory(context, category),
                onDelete: () => _deleteCategory(context, category),
              ),
            ),
        ],
      ),
    );
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

  Future<void> _showAddCategory(BuildContext context) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (result != null) {
      await ref
          .read(categoryMutationsProvider.notifier)
          .addCategory(result.category);
    }
  }

  Future<void> _showEditCategory(BuildContext context, Category category) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(initialCategory: category),
    );
    if (result != null) {
      await ref
          .read(categoryMutationsProvider.notifier)
          .updateCategory(result.category);
    }
  }

  Future<void> _deleteCategory(BuildContext context, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('确定删除"${category.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    final deleted = await ref
        .read(categoryMutationsProvider.notifier)
        .deleteCategory(category.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? '类别已删除' : '该类别已关联预算或交易，不能删除',
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.repository,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final FinanceRepository repository;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
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
                const SizedBox(height: 2),
                Text(
                  _categoryTypeLabel(category.type),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FinanceActionMenuButton<String>(
            tooltip: '类别操作',
            items: const [
              FinanceActionMenuItem(
                value: 'edit',
                label: '编辑',
                icon: Icons.edit_outlined,
              ),
              FinanceActionMenuItem(
                value: 'delete',
                label: '删除',
                icon: Icons.delete_outline,
                destructive: true,
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ],
      ),
    );
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
}
