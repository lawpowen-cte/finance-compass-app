import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
    this.color = const Color(0xFF0F766E),
  });

  final String label;
  final double value;
  final Color color;
}

class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.points,
    required this.color,
  });

  final String label;
  final List<ChartPoint> points;
  final Color color;
}

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.points,
    this.amountBuilder,
  });

  final List<ChartPoint> points;
  final String Function(double value)? amountBuilder;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('暂无数据')));
    }

    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.value));

    return SizedBox(
      height: 240,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(4, (index) {
                      final ratio = (3 - index) / 3;
                      final value = maxValue * ratio;
                      return Text(
                        amountBuilder?.call(value) ?? value.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _LineChartPainter(points),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 64),
              ...points.map(
                (point) => Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SimpleBarTable extends StatelessWidget {
  const SimpleBarTable({
    super.key,
    required this.points,
    this.amountBuilder,
  });

  final List<ChartPoint> points;
  final String Function(double value)? amountBuilder;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.value));
    return Column(
      children: points.map((point) {
        final ratio = maxValue == 0 ? 0.0 : point.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(point.label)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: ratio,
                    color: point.color,
                    backgroundColor: point.color.withValues(alpha: 0.15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                child: Text(
                  amountBuilder?.call(point.value) ?? point.value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class SimplePieLegend extends StatelessWidget {
  const SimplePieLegend({
    super.key,
    required this.points,
    this.amountBuilder,
  });

  final List<ChartPoint> points;
  final String Function(double value)? amountBuilder;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('暂无数据')));
    }

    final total = points.fold<double>(0, (sum, point) => sum + point.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: points.map((point) {
            final ratio = total == 0 ? 0 : (point.value / total * 100);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.65),
                border: Border.all(color: point.color.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: point.color),
                  const SizedBox(width: 8),
                  Text(point.label),
                  const SizedBox(width: 8),
                  Text('${ratio.toStringAsFixed(0)}%'),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(190, 190),
                  painter: _PieChartPainter(points),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '总支出',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountBuilder?.call(total) ?? total.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.points,
    this.color = const Color(0xFF0F766E),
  });

  final List<double> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(height: 24);
    }

    return SizedBox(
      height: 28,
      child: CustomPaint(
        painter: _MiniSparklinePainter(points: points, color: color),
        child: Container(),
      ),
    );
  }
}

class MultiLineChart extends StatelessWidget {
  const MultiLineChart({
    super.key,
    required this.series,
    this.amountBuilder,
  });

  final List<ChartSeries> series;
  final String Function(double value)? amountBuilder;

  @override
  Widget build(BuildContext context) {
    final nonEmptySeries = series.where((item) => item.points.isNotEmpty).toList();
    if (nonEmptySeries.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('暂无数据')));
    }

    final allPoints = nonEmptySeries.expand((item) => item.points);
    final maxValue = allPoints.fold<double>(0, (max, point) => math.max(max, point.value));
    final labels = nonEmptySeries.first.points.map((point) => point.label).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: nonEmptySeries.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 6),
                Text(item.label),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(4, (index) {
                          final ratio = (3 - index) / 3;
                          final value = maxValue * ratio;
                          return Text(
                            amountBuilder?.call(value) ?? value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: _MultiLineChartPainter(
                          series: nonEmptySeries,
                          maxValue: maxValue == 0 ? 1 : maxValue,
                        ),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 72),
                  ...labels.map(
                    (label) => Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.points);

  final List<ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x5538BDF8), Color(0x0038BDF8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final dotPaint = Paint()..color = const Color(0xFF0F766E);
    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.value));
    final safeMax = maxValue == 0 ? 1.0 : maxValue;
    const left = 8.0;
    final width = size.width - left - 12;
    final height = size.height - 12;

    for (var i = 1; i <= 3; i++) {
      final y = height - ((height - 12) * (i / 4));
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(left, height), Offset(size.width, height), axisPaint);
    canvas.drawLine(const Offset(left, 0), Offset(left, height), axisPaint);

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final dx = left + (width * (points.length == 1 ? 0 : i / (points.length - 1)));
      final dy = height - ((points[i].value / safeMax) * (height - 12));
      if (i == 0) {
        path.moveTo(dx, dy);
        fillPath.moveTo(dx, height);
        fillPath.lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
      canvas.drawCircle(Offset(dx, dy), 4, dotPaint);
    }
    fillPath.lineTo(left + width, height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter(this.points);

  final List<ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.fold<double>(0, (sum, point) => sum + point.value);
    if (total <= 0) {
      return;
    }
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    var startAngle = -math.pi / 2;
    for (final point in points) {
      final sweep = (point.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = point.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      (size.width - 16) * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MiniSparklinePainter extends CustomPainter {
  _MiniSparklinePainter({
    required this.points,
    required this.color,
  });

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final safeMax = points.reduce(math.max);
    final safeMin = points.reduce(math.min);
    final range = (safeMax - safeMin).abs() < 0.0001 ? 1.0 : safeMax - safeMin;
    final path = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final dx = size.width * (points.length == 1 ? 0 : i / (points.length - 1));
      final dy = size.height - (((points[i] - safeMin) / range) * (size.height - 4)) - 2;
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MultiLineChartPainter extends CustomPainter {
  _MultiLineChartPainter({
    required this.series,
    required this.maxValue,
  });

  final List<ChartSeries> series;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;
    const left = 8.0;
    final width = size.width - left - 12;
    final height = size.height - 12;

    for (var i = 1; i <= 3; i++) {
      final y = height - ((height - 12) * (i / 4));
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(left, height), Offset(size.width, height), axisPaint);
    canvas.drawLine(const Offset(left, 0), Offset(left, height), axisPaint);

    for (final item in series) {
      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final dotPaint = Paint()..color = item.color;
      final path = Path();

      for (var i = 0; i < item.points.length; i++) {
        final dx = left + (width * (item.points.length == 1 ? 0 : i / (item.points.length - 1)));
        final dy = height - ((item.points[i].value / maxValue) * (height - 12));
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
        canvas.drawCircle(Offset(dx, dy), 3.5, dotPaint);
      }

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
