// lib/features/statistics/presentation/widgets/current_month_summary.dart
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';
import 'stat_components.dart';

class CurrentMonthSummary extends StatelessWidget {
  final MonthlyStatistics statistics;
  final bool isRefreshing;

  const CurrentMonthSummary({
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
          mainAxisSize: MainAxisSize.min,
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

    if (statistics.weeks.isEmpty) {
      return _buildNoDataMessage();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...statistics.weeks.map((week) => _buildWeekItem(context, week)),
        const StatLegend(),
      ],
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
          Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statistics.monthName,
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

  Widget _buildWeekItem(BuildContext context, WeeklyStatistics week) {
    final total =
        week.completedCount + week.skippedCount + week.pendingCount;
    return StatRow(
      label: 'Semana ${week.weekNumber}',
      completed: week.completedCount,
      skipped: week.skippedCount,
      pending: week.pendingCount,
      trailing: total > 0 ? '${week.completedCount}/$total' : null,
    );
  }

  Widget _buildNoDataMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay datos para este mes',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
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
      height: 240, // Fixed height to prevent layout jumps
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analizando datos de la semana',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculando progreso...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline.withOpacity(0.7),
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
