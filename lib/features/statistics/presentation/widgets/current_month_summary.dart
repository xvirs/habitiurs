import 'package:flutter/material.dart';
import '../../domain/entities/statistics.dart';

class CurrentMonthSummary extends StatelessWidget {
  final MonthlyStatistics statistics;

  const CurrentMonthSummary({
    super.key,
    required this.statistics,
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
            // Si no hay semanas, mostramos un mensaje más visible
            if (statistics.weeks.isEmpty)
              _buildNoDataMessage()
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildWeeksList(),
              ),
          ],
        ),
      ),
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
        const SizedBox(height: 8), // Adjusted from width: 8 to height: 8 for consistent vertical spacing after icon if no text beside it
        Expanded(
          child: Text(
            '${statistics.monthName} ${statistics.year}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeeksList() {
    return statistics.weeks.map((week) {
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

  Widget _buildNoDataMessage() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 40.0), // Aumentar padding para que ocupe más espacio
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'No hay registros de hábitos este mes',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}