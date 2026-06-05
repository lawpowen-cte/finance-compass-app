import 'package:flutter/material.dart';

class FinanceStatusChip extends StatelessWidget {
  const FinanceStatusChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.compact = true,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;
    final horizontalPadding = compact ? 8.0 : 10.0;
    final verticalPadding = compact ? 3.0 : 5.0;
    final textStyle = compact
        ? theme.textTheme.labelSmall?.copyWith(fontSize: 10)
        : theme.textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 999),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.16),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle?.copyWith(
              color: chipColor.withValues(alpha: 0.86),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
