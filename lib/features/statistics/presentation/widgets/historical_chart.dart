// lib/features/statistics/presentation/widgets/historical_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../domain/entities/statistics.dart';

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;

  const HistoricalChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: const SizedBox(
          height: 250,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay datos históricos para mostrar',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int maxCount = data
        .map((e) => e.completedCount + e.skippedCount)
        .fold(0, (max, current) => max > current ? max : current);

    final int chartMaxValue = (maxCount * 1.2).ceil().clamp(1, double.maxFinite.toInt());

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            SizedBox(
              height: 190.0,
              child: CustomPaint(
                size: const Size.fromHeight(190.0),
                painter: _HistoricalChartPainter(data, chartMaxValue, Directionality.of(context)),
              ),
            ),
            const SizedBox(height: 10),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.show_chart,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Histórico de constancia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${data.length} meses',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: 'Cumplidos', color: Colors.green),
        SizedBox(width: 16),
        _LegendItem(label: 'Omitidos', color: Colors.red),
        SizedBox(width: 16),
        _LegendItem(label: '% Constancia', color: Colors.blue),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _HistoricalChartPainter extends CustomPainter {
  final List<HistoricalDataPoint> data;
  final int maxValue;
  final ui.TextDirection textDirection;

  _HistoricalChartPainter(this.data, this.maxValue, this.textDirection);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final Paint completedBarPaint = Paint()..color = Colors.green[500]!;
    final Paint skippedBarPaint = Paint()..color = Colors.red[400]!;
    final Paint rateLinePaint = Paint()
      ..color = Colors.blue[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final Paint axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.8;
    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: textDirection,
    );

    final double yAxisLabelAreaWidth = math.max(20.0, size.width * 0.08);
    final double xAxisLabelAreaHeight = math.max(15.0, size.height * 0.08);

    final double chartAreaWidth = size.width - yAxisLabelAreaWidth;
    final double chartAreaHeight = size.height - xAxisLabelAreaHeight;

    if (chartAreaHeight <= 1.0 || chartAreaWidth <= 1.0) {
      return;
    }

    final Offset chartOrigin = Offset(yAxisLabelAreaWidth, chartAreaHeight);

    canvas.drawLine(Offset(yAxisLabelAreaWidth, 0), Offset(yAxisLabelAreaWidth, chartAreaHeight), axisPaint);
    canvas.drawLine(Offset(yAxisLabelAreaWidth, chartAreaHeight), Offset(size.width, chartAreaHeight), axisPaint);

    const int yAxisSegments = 2;
    for (int i = 0; i <= yAxisSegments; i++) {
      final value = (maxValue / yAxisSegments * i).round();
      final y = chartAreaHeight - (value / maxValue * chartAreaHeight);

      textPainter.text = TextSpan(
        text: '$value',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: math.max(8.0, size.height * 0.035),
        ),
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(yAxisLabelAreaWidth - textPainter.width - 2, y - textPainter.height / 2));
    }

    final double barAndSpacingUnit = data.isNotEmpty ? chartAreaWidth / data.length : 0;
    final double barWidth = barAndSpacingUnit * 0.4;
    
    if (barWidth <= 0.5 && data.isNotEmpty) {
      return;
    }

    Offset? previousRatePoint;
    for (int i = 0; i < data.length; i++) {
      final currentData = data[i];
      final xPos = chartOrigin.dx + (i * barAndSpacingUnit) + barAndSpacingUnit / 2;

      final double completedHeight = ((currentData.completedCount / maxValue) * chartAreaHeight).clamp(0.0, chartAreaHeight);
      final double skippedHeight = ((currentData.skippedCount / maxValue) * chartAreaHeight).clamp(0.0, chartAreaHeight);

      final double rateY = chartAreaHeight - (currentData.completionRate / 100) * chartAreaHeight;

      final double barSegmentWidth = barWidth / 2.5;
      final double currentXOffset = xPos - barWidth / 2 + (barWidth - barSegmentWidth * 2) / 2;

      canvas.drawRect(
        Rect.fromLTWH(
          currentXOffset,
          chartAreaHeight - completedHeight,
          barSegmentWidth,
          completedHeight,
        ),
        completedBarPaint,
      );

      canvas.drawRect(
        Rect.fromLTWH(
          currentXOffset + barSegmentWidth + 2,
          chartAreaHeight - skippedHeight,
          barSegmentWidth,
          skippedHeight,
        ),
        skippedBarPaint,
      );

      final Offset currentRatePoint = Offset(xPos, rateY.clamp(0.0, chartAreaHeight));
      if (previousRatePoint != null) {
        canvas.drawLine(previousRatePoint, currentRatePoint, rateLinePaint);
      }
      previousRatePoint = currentRatePoint;

      textPainter.text = TextSpan(
        text: DateFormat('MMM').format(currentData.date),
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: math.max(8.0, size.height * 0.025),
        ),
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, chartAreaHeight + (xAxisLabelAreaHeight - textPainter.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _HistoricalChartPainter) {
      return oldDelegate.data != data || oldDelegate.maxValue != maxValue || oldDelegate.textDirection != textDirection;
    }
    return true;
  }
}
