import 'package:flutter/material.dart';

enum FinanceMetricTone { neutral, income, expense, warning, success }

Color financeMetricToneColor(FinanceMetricTone tone) {
  return switch (tone) {
    FinanceMetricTone.income => const Color(0xFF6AAF8A),
    FinanceMetricTone.expense => const Color(0xFFE07B7B),
    FinanceMetricTone.warning => const Color(0xFFE8A838),
    FinanceMetricTone.success => const Color(0xFF6AAF8A),
    FinanceMetricTone.neutral => const Color(0xFF5B9BD5),
  };
}

class FinanceMetricGrid extends StatelessWidget {
  const FinanceMetricGrid({
    super.key,
    required this.children,
    this.gap = 12,
    this.minItemWidth = 168,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double gap;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final estimatedColumns =
            ((availableWidth + gap) / (minItemWidth + gap)).floor();
        final columns = estimatedColumns.clamp(1, maxColumns);
        final itemWidth = (availableWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class FinanceMetricCard extends StatelessWidget {
  const FinanceMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.tone = FinanceMetricTone.neutral,
    this.color,
    this.padding = const EdgeInsets.all(12),
    this.valueSize,
  });

  final String label;
  final String value;
  final FinanceMetricTone tone;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double? valueSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metricColor = color ?? financeMetricToneColor(tone);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
        border: Border.all(
          color: metricColor.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: metricColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: metricColor,
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
