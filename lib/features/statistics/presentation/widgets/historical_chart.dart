import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math; // <-- ¡AÑADIR ESTA IMPORTACIÓN!
import '../../domain/entities/statistics.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class HistoricalChart extends StatelessWidget {
  final List<HistoricalDataPoint> data;

  const HistoricalChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: const SizedBox( // Usamos const aquí porque el contenido es fijo
          height: 250, // Altura mínima para el mensaje de no datos
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
    
    // Asegurar que chartMaxValue sea al menos 1 para evitar división por cero.
    // Usamos .clamp(1, ...) aquí.
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
            // LayoutBuilder pasa el tamaño disponible al CustomPaint.
            // El CustomPaint (y por tanto el Painter) debe dibujar dentro de ese tamaño.
            Expanded( // Usamos Expanded aquí para que el gráfico tome el espacio restante del Card.
                      // Si el padre de HistoricalChart es Flexible, este Expanded se ajustará.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // debugPrint('📊 HistoricalChart LayoutBuilder - MaxHeight: ${constraints.maxHeight}');
                  // debugPrint('📊 HistoricalChart LayoutBuilder - MaxWidth: ${constraints.maxWidth}');

                  if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                    return const SizedBox.shrink(); // No dibujar si no hay espacio válido
                  }

                  return CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight), // Pasar el tamaño real al painter
                    painter: _HistoricalChartPainter(data, chartMaxValue, Directionality.of(context)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // --- Métodos _buildHeader, _buildLegend, _buildLegendItem se mantienen iguales ---
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

// --- CLASE _HistoricalChartPainter ---
class _HistoricalChartPainter extends CustomPainter {
  final List<HistoricalDataPoint> data;
  final int maxValue;
  final ui.TextDirection textDirection;

  _HistoricalChartPainter(this.data, this.maxValue, this.textDirection);

  @override
  void paint(Canvas canvas, Size size) {
    // Depuración para ver el tamaño del lienzo
    // debugPrint('🎨 Painter.paint() - Received size: $size');
    // debugPrint('🎨 Painter.paint() - MaxValue: $maxValue');

    // Salir si el tamaño es inválido o no hay datos para dibujar
    if (data.isEmpty || size.width <= 0 || size.height <= 0) {
      // debugPrint('🎨 Painter.paint() - Invalid size or no data, returning.');
      return;
    }

    // --- Definición de Pinceles ---
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

    // --- Cálculo de áreas de dibujo ---
    // Espacio reservado para las etiquetas del eje Y (números 0, 1, 2)
    // Usamos math.max para asegurar un mínimo de 20px o el 8% del ancho.
    final double yAxisLabelAreaWidth = math.max(20.0, size.width * 0.08);

    // Espacio reservado para las etiquetas del eje X (meses: Jun)
    // Usamos math.max para asegurar un mínimo de 15px o el 8% del alto.
    final double xAxisLabelAreaHeight = math.max(15.0, size.height * 0.08);

    // El área real donde se dibujarán las barras y la línea de tasa
    final double chartAreaWidth = size.width - yAxisLabelAreaWidth;
    final double chartAreaHeight = size.height - xAxisLabelAreaHeight;
    
    // Si el área de dibujo efectiva es demasiado pequeña, salimos.
    if (chartAreaHeight <= 1.0 || chartAreaWidth <= 1.0) {
      // debugPrint('🎨 Painter.paint() - Chart area too small: W=$chartAreaWidth, H=$chartAreaHeight. Returning.');
      return;
    }

    // El origen (0,0) del sistema de coordenadas del gráfico, en la esquina inferior izquierda del área de dibujo.
    final Offset chartOrigin = Offset(yAxisLabelAreaWidth, chartAreaHeight);

    // --- Dibujar Ejes ---
    // Eje Y
    canvas.drawLine(Offset(yAxisLabelAreaWidth, 0), Offset(yAxisLabelAreaWidth, chartAreaHeight), axisPaint);
    // Eje X
    canvas.drawLine(Offset(yAxisLabelAreaWidth, chartAreaHeight), Offset(size.width, chartAreaHeight), axisPaint);

    // --- Dibujar etiquetas del Eje Y (números: 0, 1, 2) ---
    const int yAxisSegments = 2; // Para mostrar 0, 1, 2
    for (int i = 0; i <= yAxisSegments; i++) {
      final value = (maxValue / yAxisSegments * i).round();
      // Calcular la posición Y en el área del gráfico (invertida, 0 está arriba)
      final y = chartAreaHeight - (value / maxValue * chartAreaHeight); 
      
      textPainter.text = TextSpan(
        text: '$value',
        style: TextStyle(
          color: Colors.grey[600],
          // Tamaño de fuente adaptable, mínimo 8.0 para legibilidad
          fontSize: math.max(8.0, size.height * 0.035), 
        ),
      );
      textPainter.layout(); // Calcular el tamaño que ocupará el texto
      
      // Posicionar la etiqueta:
      // X: Justo a la izquierda de la línea del eje Y, con un pequeño margen.
      // Y: Centrado verticalmente en su posición.
      textPainter.paint(canvas, Offset(yAxisLabelAreaWidth - textPainter.width - 2, y - textPainter.height / 2));
    }

    // --- Cálculo de Ancho de Barras y Espacio ---
    final double barAndSpacingUnit = data.isNotEmpty ? chartAreaWidth / data.length : 0;
    final double barWidth = barAndSpacingUnit * 0.4; // 40% del espacio por mes para las barras
    final double spacing = barAndSpacingUnit * 0.6; // 60% del espacio por mes para el espacio

    // Si las barras son demasiado estrechas, no las dibujamos (o ajustamos la representación)
    if (barWidth <= 0.5 && data.length > 0) {
      // debugPrint('🎨 Painter.paint() - Bar width too small, skipping bars.');
      return; // Podríamos retornar o dibujar algo más simple
    }

    // --- Dibujar Barras y Línea de Tasa ---
    Offset? previousRatePoint;
    for (int i = 0; i < data.length; i++) {
      final currentData = data[i];
      // Centro X para cada grupo de barras (e.g., centro de "Jun")
      final xPos = chartOrigin.dx + (i * barAndSpacingUnit) + barAndSpacingUnit / 2;
      
      // Altura calculada para cada barra (antes de clamp)
      final double completedHeightCalculated = (currentData.completedCount / maxValue) * chartAreaHeight;
      final double skippedHeightCalculated = (currentData.skippedCount / maxValue) * chartAreaHeight;
      
      // Aplicar clamp para asegurar que las alturas de las barras estén dentro del área de dibujo y no sean negativas.
      final double completedHeight = completedHeightCalculated.clamp(0.0, chartAreaHeight);
      final double skippedHeight = skippedHeightCalculated.clamp(0.0, chartAreaHeight);
      
      // Calcular la posición Y para la línea de tasa de cumplimiento
      final double rateY = chartAreaHeight - (currentData.completionRate / 100) * chartAreaHeight;

      // Ancho de cada segmento de barra (cumplidos, omitidos)
      final double barSegmentWidth = barWidth / 2.5;
      // Posición X de inicio para el primer segmento de barra
      final double currentXOffset = xPos - barWidth / 2 + (barWidth - barSegmentWidth * 2) / 2;

      // Dibujar barra de "Cumplidos"
      canvas.drawRect(
        Rect.fromLTWH(
          currentXOffset,
          chartAreaHeight - completedHeight, // Y superior de la barra (eje Y invertido)
          barSegmentWidth,
          completedHeight,
        ),
        completedBarPaint,
      );
      // Dibujar barra de "Omitidos"
      canvas.drawRect(
        Rect.fromLTWH(
          currentXOffset + barSegmentWidth + 2, // Espacio de 2px entre las barras Cumplidos y Omitidos
          chartAreaHeight - skippedHeight, // Y superior de la barra
          barSegmentWidth,
          skippedHeight,
        ),
        skippedBarPaint,
      );

      // Dibujar línea de tasa de cumplimiento
      final Offset currentRatePoint = Offset(xPos, rateY.clamp(0.0, chartAreaHeight)); // Clamp para asegurar que la línea no se salga
      if (previousRatePoint != null) {
        canvas.drawLine(previousRatePoint, currentRatePoint, rateLinePaint);
      }
      previousRatePoint = currentRatePoint;

      // --- Dibujar etiquetas del Eje X (meses: Jun) ---
      textPainter.text = TextSpan(
        text: DateFormat('MMM').format(currentData.date),
        style: TextStyle(
          color: Colors.grey[700],
          // Tamaño de fuente adaptable, mínimo 8.0 para legibilidad
          fontSize: math.max(8.0, size.height * 0.025), 
        ),
      );
      textPainter.layout(); // Calcular el tamaño que ocupará el texto
      
      // Posicionar la etiqueta del mes:
      // X: Centrado debajo del grupo de barras.
      // Y: En el espacio reservado para las etiquetas del eje X, centrado verticalmente.
      textPainter.paint(canvas, Offset(xPos - textPainter.width / 2, chartAreaHeight + (xAxisLabelAreaHeight - textPainter.height) / 2));
    }
  }

  // Helper para calcular el borde izquierdo de un grupo de barras
  double barLeft(double xPos, double barWidth) => xPos - barWidth / 2;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _HistoricalChartPainter) {
      return oldDelegate.data != data || oldDelegate.maxValue != maxValue || oldDelegate.textDirection != textDirection;
    }
    return true;
  }
}