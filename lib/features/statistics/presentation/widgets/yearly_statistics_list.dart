import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class YearlyStatisticsList extends StatelessWidget {
  final List<MonthlyStatistics> statistics;
  
  const YearlyStatisticsList({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 200, // Altura fija para que el mensaje "no hay datos" se vea
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
                  'No hay datos disponibles para el año', // Mensaje más específico
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

    final bool shouldScrollInternally = statistics.length > 3;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          shouldScrollInternally
              ? SizedBox(
                  height: 200,
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
                    mainAxisSize: MainAxisSize.min,
                    children: statistics.map((monthStats) => 
                      _buildMonthItem(context, monthStats)
                    ).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
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