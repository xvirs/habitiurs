// lib/features/statistics/presentation/widgets/historical_chart.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:ui' as ui;
import '../../domain/entities/statistics.dart';

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

    return Column(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(
            painter: _HistoricalChartPainter(
              data,
              chartMaxValue,
              Directionality.of(context),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
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

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.green[400]!, label: 'Completado'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.red[300]!, label: 'Omitido'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.blue[400]!, label: '% Logro', isLine: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: isLine ? 2 : 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
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

  _HistoricalChartPainter(this.data, this.maxValue, this.textDirection);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingRight = 10.0;
    final double paddingBottom = 24.0;
    final double paddingLeft = 30.0;
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom;

    final double barWidth = chartWidth / data.length;
    final double spacing = barWidth * 0.2;
    final double actualBarWidth = barWidth - spacing;

    // Dibujar líneas de referencia Y
    final paintGrid =
        Paint()
          ..color = Colors.grey[100]!
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
          style: TextStyle(color: Colors.grey[400], fontSize: 10),
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
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = Colors.green[400]!.withOpacity(0.6),
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
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = Colors.red[300]!.withOpacity(0.6),
        );
      }

      // Etiquetas X (solo algunas para no amontonar)
      if (data.length <= 12 || i % (data.length / 6).ceil() == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: DateFormat('MMM').format(point.date),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          textDirection: textDirection,
        )..layout();
        tp.paint(
          canvas,
          Offset(x + (barWidth - tp.width) / 2, chartHeight + 4),
        );
      }
    }

    // Línea de porcentaje
    final path = Path();
    final ratePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0
          ..style = ui.PaintingStyle.stroke;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final double x = paddingLeft + i * barWidth + barWidth / 2;
      final double y = chartHeight - (point.completionRate / 100) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3, Paint()..color = Colors.blue);
    }
    canvas.drawPath(path, ratePaint);
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
