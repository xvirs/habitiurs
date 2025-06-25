// lib/features/statistics/presentation/widgets/historical_chart.dart - DISEÑO MÁS ATRACTIVO Y ALTURA AJUSTADA (CORRECCIÓN DE TextDirection)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui; 

import '../../domain/entities/statistics.dart';

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;

  const HistoricalChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 250, 
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay datos históricos para mostrar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final int maxCount = data
        .map((e) => e.completedCount + e.skippedCount)
        .reduce((a, b) => a > b ? a : b);
    final int chartMaxValue = (maxCount * 1.2).ceil();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 16),
            // ✅ MODIFICADO: Eliminar SizedBox de altura fija aquí
            Expanded( // Permitir que el contenido del gráfico tome el espacio restante del Card
              child: _buildChartContent(context, chartMaxValue),
            ),
            const SizedBox(height: 12), // Espacio entre gráfico y leyenda
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContent(BuildContext context, int chartMaxValue) {
    if (data.isEmpty) { 
      return Center(
        child: Text(
          'Se necesita al menos 1 mes de datos para el gráfico',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    final ui.TextDirection textDirection = Directionality.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight), // ✅ Usar el tamaño completo disponible
          painter: _HistoricalChartPainter(data, chartMaxValue, textDirection),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Cumplidos', Colors.green[600]!),
        const SizedBox(width: 16),
        _buildLegendItem('Omitidos', Colors.red[500]!),
        const SizedBox(width: 16),
        _buildLegendItem('% Constancia', Colors.blue[600]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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
    if (data.isEmpty) return;

    final completedBarPaint = Paint()..color = Colors.green[500]!;
    final skippedBarPaint = Paint()..color = Colors.red[400]!;
    final rateLinePaint = Paint()
      ..color = Colors.blue[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: textDirection, 
    );

    const double yAxisLabelWidth = 20.0;
    const double xAxisLabelHeight = 15.0;
    final double chartAreaWidth = size.width - yAxisLabelWidth;
    final double chartAreaHeight = size.height - xAxisLabelHeight;
    final Offset chartOrigin = Offset(yAxisLabelWidth, chartAreaHeight);

    canvas.drawLine(
        Offset(yAxisLabelWidth, 0), Offset(yAxisLabelWidth, chartAreaHeight), axisPaint);

    canvas.drawLine(
        Offset(yAxisLabelWidth, chartAreaHeight), Offset(size.width, chartAreaHeight), axisPaint);

    final int yAxisSegments = 2;
    for (int i = 0; i <= yAxisSegments; i++) {
      final value = (maxValue / yAxisSegments * i).round();
      final y = chartAreaHeight - (value / maxValue * chartAreaHeight);

      textPainter.text = TextSpan(
        text: '$value',
        style: TextStyle(color: Colors.grey[600], fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(yAxisLabelWidth - textPainter.width - 5, y - textPainter.height / 2));
    }

    final double barWidth = (chartAreaWidth / data.length) * 0.4;
    final double spacing = (chartAreaWidth / data.length) * 0.6;

    Offset? previousRatePoint;

    for (int i = 0; i < data.length; i++) {
      final currentData = data[i];
      final xPos = chartOrigin.dx + (i * (barWidth + spacing) + spacing / 2);
      final barLeft = xPos - barWidth / 2;
      
      final completedHeight = (currentData.completedCount / maxValue) * chartAreaHeight;
      final skippedHeight = (currentData.skippedCount / maxValue) * chartAreaHeight;
      final rateY = chartAreaHeight - (currentData.completionRate / 100) * chartAreaHeight;

      final double barSegmentWidth = barWidth / 2.5;
      final double currentXOffset = barLeft + (barWidth - barSegmentWidth * 2) / 2;

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

      final currentRatePoint = Offset(xPos, rateY);
      if (previousRatePoint != null) {
        canvas.drawLine(previousRatePoint, currentRatePoint, rateLinePaint);
      }
      previousRatePoint = currentRatePoint;

      textPainter.text = TextSpan(
        text: DateFormat('MMM').format(currentData.date),
        style: TextStyle(color: Colors.grey[700], fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, chartAreaHeight + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}