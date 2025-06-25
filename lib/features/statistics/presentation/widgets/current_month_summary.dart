// lib/features/statistics/presentation/widgets/current_month_summary.dart - MODIFICADO (Método de altura como static)

import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class CurrentMonthSummary extends StatelessWidget {
  final MonthlyStatistics statistics;

  const CurrentMonthSummary({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  // ✅ CORREGIDO: Método para calcular la altura mínima del contenido de las semanas (AHORA ES STATIC)
  static double calculateMinHeightForContent(MonthlyStatistics statistics) {
    // Altura del header dentro del Card (Icon, Text, SizedBox, etc.)
    const double headerRowHeight = 20.0; // Altura aproximada de la Row del título
    const double headerPaddingVertical = 16.0; // Padding top/bottom del Padding que envuelve el Header
    const double sizedBoxAfterHeader = 16.0; // SizedBox entre Header y _buildWeeksList()

    // Altura por cada semana + margin inferior de cada semana
    // Medidas aproximadas de un _buildWeekItem:
    // Container tiene vertical: 8 -> padding total vertical 16
    // Text 'Semana X' + Text 'X%' + iconos pequeños = ~30px de alto de contenido
    // Total approx: 16 (padding) + 30 (contenido) + 6 (margin bottom) = 52px
    const double weekItemTotalHeight = 52.0; 

    final int weeksToDisplay = statistics.weeks.length; // Usamos el número real de semanas en los datos

    // Altura total:
    // (Altura del Padding del Card) + Altura Header + Altura SizedBox + (Altura de todas las semanas)
    // El padding total del Card es 16 arriba y 16 abajo.
    const double cardPaddingVertical = 16.0 * 2; // Padding del Card vertical
    
    // Altura del contenido de las semanas. Si no hay semanas, es 0.
    final double totalWeeksListHeight = weeksToDisplay * weekItemTotalHeight; 

    // Suma todos los componentes para la altura mínima del Card
    // Es una aproximación, puede requerir ajustes finos en tu UI real.
    return headerRowHeight + headerPaddingVertical + sizedBoxAfterHeader + totalWeeksListHeight + cardPaddingVertical;
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      // ✅ MODIFIED: Removed top margin to align with the top of its parent Expanded
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Sigue siendo útil para que la Column se ajuste al contenido
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
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${statistics.monthName} ${statistics.year}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ✅ Modificado: _buildWeeksList ahora retorna List<Widget>
            Column( 
              mainAxisSize: MainAxisSize.min,
              children: _buildWeeksList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeeksList() {
    return statistics.weeks.asMap().entries.map((entry) {
      final week = entry.value;
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              'Semana ${week.weekNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildStatText(
                    week.completedCount.toString(),
                    Colors.green[600]!,
                  ),
                  const SizedBox(width: 8),
                  _buildStatText(
                    week.skippedCount.toString(),
                    Colors.red[500]!,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatText(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}