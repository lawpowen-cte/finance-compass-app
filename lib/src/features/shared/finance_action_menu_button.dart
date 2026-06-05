import 'package:flutter/material.dart';

class FinanceActionMenuItem<T> {
  const FinanceActionMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.dividerBefore = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool dividerBefore;
}

class FinanceActionMenuButton<T> extends StatelessWidget {
  const FinanceActionMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.tooltip = '更多操作',
    this.iconSize = 18,
    this.compact = true,
  });

  final List<FinanceActionMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final double iconSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodySmall?.color;
    return PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      iconSize: iconSize,
      tooltip: tooltip,
      icon: Icon(Icons.more_horiz, size: iconSize, color: iconColor),
      onSelected: onSelected,
      itemBuilder: (context) {
        final menuEntries = <PopupMenuEntry<T>>[];
        for (final item in items) {
          if (item.dividerBefore) {
            menuEntries.add(const PopupMenuDivider());
          }
          final color =
              item.destructive ? Theme.of(context).colorScheme.error : null;
          menuEntries.add(
            PopupMenuItem<T>(
              value: item.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: compact ? 16 : 18, color: color),
                    const SizedBox(width: 8),
                  ],
                  Text(item.label, style: TextStyle(color: color)),
                ],
              ),
            ),
          );
        }
        return menuEntries;
      },
    );
  }
}
