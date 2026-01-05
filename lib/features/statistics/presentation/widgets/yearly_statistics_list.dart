// lib/features/statistics/presentation/widgets/yearly_statistics_list.dart
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class YearlyStatisticsList extends StatelessWidget {
  final List<MonthlyStatistics> statistics;
  final bool isRefreshing;

  const YearlyStatisticsList({
    super.key,
    required this.statistics,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure Column takes minimum space
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
    if (isRefreshing) return const _LoadingState();

    if (statistics.isEmpty) {
      return const _EmptyState();
    }

    // Usar un Column en lugar de ListView para evitar conflictos de scroll
    // o asegurar que shrinkWrap esté activo y physics sea NeverScrollableScrollPhysics
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: statistics.map((month) => _buildMonthItem(month)).toList(),
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
          Icons.trending_up,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Estadísticas del año',
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

  Widget _buildMonthItem(MonthlyStatistics stats) {
    final completionRate = stats.completionRate;
    final color =
        completionRate >= 70
            ? Colors.green[600]!
            : completionRate >= 40
            ? Colors.orange[400]!
            : Colors.red[400]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              stats.monthName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildStatBadge(
                  Icons.check_circle_outline,
                  stats.completedCount.toString(),
                  Colors.green[600]!,
                ),
                const SizedBox(width: 6),
                _buildStatBadge(
                  Icons.highlight_off,
                  stats.skippedCount.toString(),
                  Colors.red[400]!,
                ),
                const SizedBox(width: 6),
                _buildStatBadge(
                  Icons.access_time,
                  stats.pendingCount.toString(),
                  Colors.orange[400]!,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${completionRate.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.7)),
          const SizedBox(width: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200, // Fixed height to prevent layout jumps
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Actualizando estadísticas',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calculando datos anuales...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay datos disponibles para el año',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
