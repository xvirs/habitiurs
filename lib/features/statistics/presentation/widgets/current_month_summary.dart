// lib/features/statistics/presentation/widgets/current_month_summary.dart
import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class CurrentMonthSummary extends StatelessWidget {
  final MonthlyStatistics statistics;

  const CurrentMonthSummary({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${statistics.monthName} ${statistics.year}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeksList() {
    return Column(
      children: statistics.weeks.asMap().entries.map((entry) {
        final week = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Semana compacta
              Text(
                'Semana ${week.weekNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              // Stats compactos
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStatChip(
                      'Cumplidos',
                      week.completedCount.toString(),
                      Colors.green[100]!,
                      Colors.green[800]!,
                    ),
                    const SizedBox(width: 6),
                    _buildStatChip(
                      'No cumplidos',
                      week.skippedCount.toString(),
                      Colors.red[100]!,
                      Colors.red[800]!,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatChip(String label, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}