import 'package:flutter/material.dart';

class FinanceFilterChipData {
  const FinanceFilterChipData({
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;
}

class FinanceFilterBar extends StatelessWidget {
  const FinanceFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.activeFilters,
    required this.onReset,
    required this.expanded,
    required this.onToggleExpanded,
    this.expandedChild,
    this.searchLabel = '搜索',
    this.searchHint,
    this.expandLabel = '展开详细筛选',
    this.collapseLabel = '收起详细筛选',
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final List<FinanceFilterChipData> activeFilters;
  final VoidCallback onReset;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final Widget? expandedChild;
  final String searchLabel;
  final String? searchHint;
  final String expandLabel;
  final String collapseLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: searchLabel,
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: '清除搜索',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...activeFilters.map(
                (filter) => InputChip(
                  label: Text(filter.label),
                  visualDensity: VisualDensity.compact,
                  onDeleted: filter.onClear,
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('重置'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(expanded ? collapseLabel : expandLabel)),
                Icon(expanded ? Icons.expand_less : Icons.tune),
              ],
            ),
          ),
        ),
        if (expandedChild != null && expanded) ...[
          const SizedBox(height: 12),
          expandedChild!,
        ],
      ],
    );
  }
}
