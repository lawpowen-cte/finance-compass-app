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

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({super.key, required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No data')));
    }

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(points),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points
                .map((point) => Expanded(
                      child: Text(
                        point.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class SimpleBarTable extends StatelessWidget {
  const SimpleBarTable({super.key, required this.points});

  final List<ChartPoint> points;

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
                width: 96,
                child: Text(
                  point.value.toStringAsFixed(0),
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
  const SimplePieLegend({super.key, required this.points});

  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No data')));
    }

    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _PieChartPainter(points),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: point.color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point.label)),
                    Text(point.value.toStringAsFixed(0)),
                  ],
                ),
              );
            }).toList(),
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
    final dotPaint = Paint()..color = const Color(0xFF0F766E);
    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.value));
    final safeMax = maxValue == 0 ? 1.0 : maxValue;
    const left = 12.0;
    final width = size.width - left - 12;
    final height = size.height - 12;

    for (var i = 1; i <= 3; i++) {
      final y = height - ((height - 12) * (i / 4));
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawLine(Offset(left, height), Offset(size.width, height), axisPaint);
    canvas.drawLine(const Offset(left, 0), Offset(left, height), axisPaint);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final dx = left + (width * (points.length == 1 ? 0 : i / (points.length - 1)));
      final dy = height - ((points[i].value / safeMax) * (height - 12));
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
      canvas.drawCircle(Offset(dx, dy), 4, dotPaint);
    }
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
      (size.width - 16) * 0.22,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
