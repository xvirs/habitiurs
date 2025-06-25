// lib/features/statistics/presentation/widgets/yearly_statistics_list.dart - DISEÑO MINIMALISTA
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class YearlyStatisticsList extends StatelessWidget {
  final List<MonthlyStatistics> statistics;
  const YearlyStatisticsList({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  // ✅ NUEVO: Método para calcular la altura mínima del CONTENIDO del Card
  // Si no scrollea, esta es la altura que toma.
  static double calculateMinHeightForContent(List<MonthlyStatistics> stats) {
    // Altura del padding interno del Card (16 top + 16 bottom)
    const double cardInnerPaddingVertical = 16.0 * 2; 
    // Altura del header (padding 16 + Row height ~20)
    const double headerHeight = 16.0; // Solo padding top/bottom de la fila del header
    const double headerRowVisualHeight = 20.0; // Altura de la fila de texto/icono del header
    const double headerPaddingBottom = 16.0; // padding inferior del Padding que envuelve la Row del header

    // Altura de cada item mensual (margin bottom 8 + padding vertical 8 + text height ~15)
    // Contenedor tiene padding horizontal:12, vertical:8. Margin bottom 8.
    // Altura del texto dentro del item (aprox. 13 + line-height).
    const double monthItemHeight = (8.0 * 2) + 13.0; // Vertical padding + text height
    const double monthItemMarginBottom = 8.0;

    final int monthsToDisplay = stats.length;
    final double totalMonthsListHeight = monthsToDisplay * (monthItemHeight + monthItemMarginBottom);

    return cardInnerPaddingVertical + headerHeight + headerRowVisualHeight + headerPaddingBottom + totalMonthsListHeight;
  }


  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
        child: Container(
          height: 200, 
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // `shouldScroll` ya está en tu código, pero no lo usaremos para decidir la altura EXTERNA.
    final bool shouldScrollInternally = statistics.length > 3; // Lógica para scroll interno

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Sigue ajustándose al contenido
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estadísticas del año ${DateTime.now().year}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ✅ MODIFICADO: El contenedor interno de la lista.
          // Si scrollea, lo limitamos con SizedBox para que no ocupe demasiado.
          // Si no scrollea, se ajusta a su contenido.
          shouldScrollInternally 
            ? SizedBox(
                height: 200, // Altura fija si tiene scroll interno. Ajusta este valor si es necesario.
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: statistics.length,
                  itemBuilder: (context, index) {
                    final monthStats = statistics[index];
                    return _buildMonthItem(context, monthStats);
                  },
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Asegura que Column se ajusta al contenido
                  children: statistics.map((monthStats) => 
                    _buildMonthItem(context, monthStats)
                  ).toList(),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(BuildContext context, MonthlyStatistics stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          Expanded(
            flex: 2,
            child: Text(
              stats.monthName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(
                color: _getPercentageColor(stats.completionRate).withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${stats.completionRate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getPercentageColor(stats.completionRate),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              _buildStatText(
                stats.completedCount.toString(),
                Colors.green[600]!,
              ),
              const SizedBox(width: 4),
              _buildStatText(
                stats.skippedCount.toString(),
                Colors.red[500]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 70) return Colors.green[600]!;
    if (percentage >= 40) return Colors.orange[600]!;
    return Colors.red[600]!;
  }
}