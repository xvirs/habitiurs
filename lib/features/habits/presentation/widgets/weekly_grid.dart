// lib/features/habits/presentation/widgets/weekly_grid.dart - VISTA SIMPLE NO SCROLLEABLE
import 'package:flutter/material.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';

class WeeklyGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitEntry> weekEntries;
  final DateTime weekStart;
  
  const WeeklyGrid({
    super.key,
    required this.habits,
    required this.weekEntries,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    final weekDates = AppDateUtils.getWeekDates(weekStart);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header simple
            _buildHeader(context, weekDates),
            const SizedBox(height: 16),
            
            // Headers de días
            _buildDaysHeader(context, weekDates),
            const SizedBox(height: 12),
            
            // Grid de hábitos (expandido para ocupar todo el espacio disponible)
            Expanded(
              child: _buildFixedGrid(context, weekDates),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<DateTime> weekDates) {
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
          Icons.view_week,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Vista semanal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '${weekDates.first.day} - ${weekDates.last.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysHeader(BuildContext context, List<DateTime> weekDates) {
    return Row(
      children: [
        // Espacio para números de hábitos
        const SizedBox(width: 28),
        // Headers de días
        ...AppDateUtils.weekDayNames.asMap().entries.map((entry) {
          final index = entry.key;
          final dayName = entry.value;
          final date = weekDates[index];
          final isToday = AppDateUtils.isToday(date);

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: isToday
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    dayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      color: isToday 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: isToday 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFixedGrid(BuildContext context, List<DateTime> weekDates) {
    if (habits.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: habits.asMap().entries.map((entry) {
        final index = entry.key;
        final habit = entry.value;
        return Expanded(
          child: _buildHabitRow(context, habit, index, weekDates),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_week,
            size: 40,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes hábitos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRow(BuildContext context, Habit habit, int index, List<DateTime> weekDates) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          // Número del hábito
          _buildHabitNumber(context, index),
          const SizedBox(width: 4),
          // Celdas de días
          ..._buildDayCells(context, habit, weekDates),
        ],
      ),
    );
  }

  Widget _buildHabitNumber(BuildContext context, int index) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDayCells(BuildContext context, Habit habit, List<DateTime> weekDates) {
    return weekDates.map((date) {
      final entry = _findEntryForDate(habit.id!, date);
      final status = entry?.status ?? HabitStatus.pending;
      final isToday = AppDateUtils.isToday(date);
      final isPastDate = AppDateUtils.isPastDate(date);

      // Auto-skip logic: días pasados sin entrada se consideran "skipped"
      final displayStatus = (isPastDate && entry == null) 
          ? HabitStatus.skipped 
          : status;

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          height: 24,
          decoration: BoxDecoration(
            color: _getCellColor(displayStatus, isToday),
            border: isToday ? Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ) : null,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }).toList();
  }

  Color _getCellColor(HabitStatus status, bool isToday) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[500]!;
      case HabitStatus.skipped:
        return Colors.red[400]!;
      case HabitStatus.pending:
        return Colors.grey[200]!;
    }
  }

  HabitEntry? _findEntryForDate(int habitId, DateTime date) {
    try {
      return weekEntries.firstWhere(
        (e) => e.habitId == habitId && AppDateUtils.isSameDay(e.date, date),
      );
    } catch (e) {
      return null;
    }
  }
}