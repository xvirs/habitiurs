// lib/features/statistics/presentation/widgets/historical_chart.dart
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;

  const HistoricalChart({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Container(
          height: 200,
          child: const Center(
            child: Text(
              'No hay datos históricos suficientes',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
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
            Text(
              'Histórico de constancia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildSimpleChart(context),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context) {
    if (data.length < 2) {
      return const Center(
        child: Text(
          'Se necesitan al menos 2 meses de datos',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final maxValue = data.map((e) => e.completedCount + e.skippedCount).reduce((a, b) => a > b ? a : b);
    final chartWidth = MediaQuery.of(context).size.width - 64; // Ancho disponible

    return CustomPaint(
      size: Size(chartWidth, 200),
      painter: _HistoricalChartPainter(data, maxValue),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Cumplidos', Colors.green),
        const SizedBox(width: 20),
        _buildLegendItem('No cumplidos', Colors.red),
        const SizedBox(width: 20),
        _buildLegendItem('% Constancia', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
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
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final completedPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final skippedPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final ratePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dibujar ejes
    final axisPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Eje Y
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      axisPaint,
    );

    // Eje X
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    if (data.isEmpty) return;

    final stepX = size.width / (data.length - 1);
    final stepY = size.height / maxValue;

    // Dibujar líneas
    for (int i = 0; i < data.length - 1; i++) {
      final currentX = i * stepX;
      final nextX = (i + 1) * stepX;

      // Línea de completados
      final currentCompletedY = size.height - (data[i].completedCount * stepY);
      final nextCompletedY = size.height - (data[i + 1].completedCount * stepY);
      
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

      // Línea de porcentaje (escalada a 100)
      final currentRateY = size.height - ((data[i].completionRate / 100) * size.height);
      final nextRateY = size.height - ((data[i + 1].completionRate / 100) * size.height);
      
      canvas.drawLine(
        Offset(currentX, currentRateY),
        Offset(nextX, nextRateY),
        ratePaint,
      );
    }

    // Dibujar puntos
    final pointPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;

      // Punto completados
      pointPaint.color = Colors.green;
      final completedY = size.height - (data[i].completedCount * stepY);
      canvas.drawCircle(Offset(x, completedY), 4, pointPaint);

      // Punto no cumplidos
      pointPaint.color = Colors.red;
      final skippedY = size.height - (data[i].skippedCount * stepY);
      canvas.drawCircle(Offset(x, skippedY), 4, pointPaint);

      // Punto porcentaje
      pointPaint.color = Colors.blue;
      final rateY = size.height - ((data[i].completionRate / 100) * size.height);
      canvas.drawCircle(Offset(x, rateY), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}