// lib/features/statistics/presentation/widgets/historical_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' as ui;
import '../../domain/entities/statistics.dart';
import 'stat_components.dart';

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;
  final bool isRefreshing;

  const HistoricalChart({
    super.key,
    required this.data,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isRefreshing) return const _LoadingContent();

    if (data.isEmpty) {
      return const _EmptyState();
    }

    final int maxCount = data
        .map((e) => e.completedCount + e.skippedCount)
        .fold(0, (max, current) => max > current ? max : current);

    final int chartMaxValue = (maxCount * 1.2).ceil().clamp(
      1,
      double.maxFinite.toInt(),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(
            painter: _HistoricalChartPainter(
              data,
              chartMaxValue,
              Directionality.of(context),
              completedColor: StatColors.completed(context),
              skippedColor: StatColors.skipped(context).withValues(alpha: 0.85),
              lineColor: theme.colorScheme.primary,
              gridColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.4,
              ),
              labelColor: theme.colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StatLegend(
          entries: [
            StatLegendEntry(StatColors.completed(context), 'Completados'),
            StatLegendEntry(StatColors.skipped(context), 'No realizados'),
            StatLegendEntry(theme.colorScheme.primary, '% Logro', isLine: true),
          ],
        ),
      ],
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _HistoricalChartPainter extends CustomPainter {
  final List<HistoricalDataPoint> data;
  final int maxValue;
  final TextDirection? textDirection;
  final Color completedColor;
  final Color skippedColor;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  _HistoricalChartPainter(
    this.data,
    this.maxValue,
    this.textDirection, {
    required this.completedColor,
    required this.skippedColor,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingRight = 10.0;
    final double paddingBottom = 24.0;
    final double paddingLeft = 30.0;
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom;

    final double barWidth = chartWidth / data.length;
    final double spacing = barWidth * 0.35;
    final double actualBarWidth = barWidth - spacing;
    final Radius barRadius = Radius.circular(actualBarWidth / 3);

    // Dibujar líneas de referencia Y
    final paintGrid =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final double y = chartHeight - (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: ((maxValue / 4) * i).toInt().toString(),
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: textDirection,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 8, y - tp.height / 2));
    }

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final double x = paddingLeft + i * barWidth + spacing / 2;

      // Barras apiladas
      final double completedHeight =
          (point.completedCount / maxValue) * chartHeight;
      final double skippedHeight =
          (point.skippedCount / maxValue) * chartHeight;

      if (point.completedCount > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              x,
              chartHeight - completedHeight,
              actualBarWidth,
              completedHeight,
            ),
            topLeft: skippedHeight > 0 ? Radius.zero : barRadius,
            topRight: skippedHeight > 0 ? Radius.zero : barRadius,
          ),
          Paint()..color = completedColor,
        );
      }

      if (point.skippedCount > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              x,
              chartHeight - completedHeight - skippedHeight,
              actualBarWidth,
              skippedHeight,
            ),
            topLeft: barRadius,
            topRight: barRadius,
          ),
          Paint()..color = skippedColor,
        );
      }

      // Etiquetas X (solo algunas para no amontonar)
      if (data.length <= 12 || i % (data.length / 6).ceil() == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: DateFormat('MMM').format(point.date),
            style: TextStyle(color: labelColor, fontSize: 10),
          ),
          textDirection: textDirection,
        )..layout();
        tp.paint(
          canvas,
          Offset(x + (actualBarWidth - tp.width) / 2, chartHeight + 4),
        );
      }
    }

    // Línea de porcentaje de logro
    final path = Path();
    final ratePaint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2.0
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..style = ui.PaintingStyle.stroke;

    final dotFill = Paint()..color = lineColor;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final double x = paddingLeft + i * barWidth + barWidth / 2;
      final double y = chartHeight - (point.completionRate / 100) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, ratePaint);

    // Puntos sobre la línea (encima del trazo para que queden nítidos)
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final double x = paddingLeft + i * barWidth + barWidth / 2;
      final double y = chartHeight - (point.completionRate / 100) * chartHeight;
      canvas.drawCircle(Offset(x, y), 2.5, dotFill);
    }
  }

  @override
  bool shouldRepaint(_HistoricalChartPainter oldDelegate) =>
      data != oldDelegate.data || maxValue != oldDelegate.maxValue;
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220, // Fixed height to prevent layout jumps
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Generando gráfico histórico...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
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
    );
  }
}
