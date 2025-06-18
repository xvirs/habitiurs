// lib/features/statistics/presentation/widgets/yearly_statistics_list.dart - DISEÑO MINIMALISTA
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
      return Card(
        margin: const EdgeInsets.all(16),
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

    final shouldScroll = statistics.length > 3;
    final containerHeight = shouldScroll 
        ? 240.0 
        : (statistics.length * 60.0) + 16;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con diseño consistente
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
          // Nombre del mes
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
          // Porcentaje
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
          // Stats simples
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