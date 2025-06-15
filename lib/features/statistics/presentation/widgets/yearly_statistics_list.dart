// lib/features/statistics/presentation/widgets/yearly_statistics_list.dart
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class YearlyStatisticsList extends StatelessWidget {
  final List<MonthlyStatistics> statistics;

  const YearlyStatisticsList({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No hay datos históricos disponibles',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    // Calcular altura dinámica
    final shouldScroll = statistics.length > 3;
    final containerHeight = shouldScroll 
        ? 240.0 // Altura fija para scroll si hay más de 3 meses
        : (statistics.length * 80.0) + 16; // Altura dinámica para 1-3 meses

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Estadísticas del año ${DateTime.now().year}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: containerHeight,
            child: shouldScroll 
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: statistics.length,
                    itemBuilder: (context, index) {
                      final monthStats = statistics[index];
                      return _buildMonthItem(context, monthStats);
                    },
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: statistics.map((monthStats) => 
                        _buildMonthItem(context, monthStats)
                      ).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(BuildContext context, MonthlyStatistics stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Nombre del mes
          Expanded(
            flex: 2,
            child: Text(
              stats.monthName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Porcentaje
          SizedBox(
            width: 50,
            child: Text(
              '${stats.completionRate.toStringAsFixed(0)}%',
              style: TextStyle(
                color: stats.completionRate >= 70 
                  ? Colors.green[600] 
                  : stats.completionRate >= 40 
                    ? Colors.orange[600] 
                    : Colors.red[600],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Stats badges compactos
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStatBadge(
                  'C',
                  stats.completedCount,
                  Colors.green[100]!,
                  Colors.green[800]!,
                ),
                const SizedBox(width: 4),
                _buildStatBadge(
                  'X',
                  stats.skippedCount,
                  Colors.red[100]!,
                  Colors.red[800]!,
                ),
                const SizedBox(width: 4),
                _buildStatBadge(
                  'P',
                  stats.pendingCount,
                  Colors.grey[200]!,
                  Colors.grey[800]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}