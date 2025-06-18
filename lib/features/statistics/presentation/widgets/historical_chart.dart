// lib/features/statistics/presentation/widgets/historical_chart.dart - DISEÑO MINIMALISTA
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;

  const HistoricalChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay datos históricos',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con diseño consistente
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
            SizedBox(height: 180, child: _buildSimpleChart(context)),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    if (data.length < 1) {
      return Center(
        child: Text(
          'Se necesita al menos 1 mes de datos',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    final maxValue = data
        .map((e) => e.completedCount + e.skippedCount)
        .reduce((a, b) => a > b ? a : b);
    final chartWidth = MediaQuery.of(context).size.width - 64;

    return CustomPaint(
      size: Size(chartWidth, 180),
      painter: _HistoricalChartPainter(data, maxValue),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Cumplidos', Colors.green[600]!),
        const SizedBox(width: 16),
        _buildLegendItem('No cumplidos', Colors.red[500]!),
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

  _HistoricalChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Configuración de colores más delicados
    final completedPaint =
        Paint()
          ..color = Colors.green[600]!
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final skippedPaint =
        Paint()
          ..color = Colors.red[500]!
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final ratePaint =
        Paint()
          ..color = Colors.blue[600]!
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    // Ejes más sutiles
    final axisPaint =
        Paint()
          ..color = Colors.grey[200]!
          ..strokeWidth = 0.5;

    // Eje Y
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axisPaint);

    // Eje X
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    // Calcular pasos para comenzar desde el primer dato
    final stepX =
        data.length == 1 ? size.width : size.width / (data.length - 1);
    final stepY = maxValue == 0 ? 0 : size.height / maxValue;

    // Dibujar líneas si hay más de un punto
    if (data.length > 1) {
      for (int i = 0; i < data.length - 1; i++) {
        final currentX = i * stepX;
        final nextX = (i + 1) * stepX;

        // Línea de completados
        final currentCompletedY =
            size.height - (data[i].completedCount * stepY);
        final nextCompletedY =
            size.height - (data[i + 1].completedCount * stepY);

        canvas.drawLine(
          Offset(currentX, currentCompletedY),
          Offset(nextX, nextCompletedY),
          completedPaint,
        );

        // Línea de no cumplidos
        final currentSkippedY = size.height - (data[i].skippedCount * stepY);
        final nextSkippedY = size.height - (data[i + 1].skippedCount * stepY);

        canvas.drawLine(
          Offset(currentX, currentSkippedY),
          Offset(nextX, nextSkippedY),
          skippedPaint,
        );

        // Línea de porcentaje
        final currentRateY =
            size.height - ((data[i].completionRate / 100) * size.height);
        final nextRateY =
            size.height - ((data[i + 1].completionRate / 100) * size.height);

        canvas.drawLine(
          Offset(currentX, currentRateY),
          Offset(nextX, nextRateY),
          ratePaint,
        );
      }
    }

    // Dibujar puntos (incluso para un solo dato)
    final pointPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1 ? size.width / 2 : i * stepX;

      // Punto completados
      pointPaint.color = Colors.green[600]!;
      final completedY = size.height - (data[i].completedCount * stepY);
      canvas.drawCircle(Offset(x, completedY), 3, pointPaint);

      // Punto no cumplidos
      pointPaint.color = Colors.red[500]!;
      final skippedY = size.height - (data[i].skippedCount * stepY);
      canvas.drawCircle(Offset(x, skippedY), 3, pointPaint);

      // Punto porcentaje
      pointPaint.color = Colors.blue[600]!;
      final rateY =
          size.height - ((data[i].completionRate / 100) * size.height);
      canvas.drawCircle(Offset(x, rateY), 2, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
