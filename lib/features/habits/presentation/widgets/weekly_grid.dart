// lib/features/habits/presentation/widgets/weekly_grid.dart - UI MEJORADA
import 'package:flutter/material.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../widgets/habit_status_icon.dart';
import '../../../../shared/enums/habit_status.dart';

class WeeklyGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitEntry> weekEntries;
  final DateTime weekStart;
  final Function(int habitId, DateTime date, HabitStatus currentStatus) onToggle;
  final Function(int habitId) onDelete;

  const WeeklyGrid({
    super.key,
    required this.habits,
    required this.weekEntries,
    required this.weekStart,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final weekDates = AppDateUtils.getWeekDates(weekStart);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con estilo mejorado
          Text(
            'Vista semanal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(context, weekDates),
          const SizedBox(height: 12),
          Expanded(
            child: _buildGrid(context, weekDates),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<DateTime> weekDates) {
    return Row(
      children: [
        // Espacio para números de hábitos
        const SizedBox(width: 50),
        // Días de la semana
        ...AppDateUtils.weekDayNames.asMap().entries.map((entry) {
          final index = entry.key;
          final dayName = entry.value;
          final date = weekDates[index];
          final isToday = AppDateUtils.isToday(date);

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: isToday
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    dayName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    '${date.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday 
                          ? Theme.of(context).colorScheme.primary 
                          : Colors.grey[600],
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

  Widget _buildGrid(BuildContext context, List<DateTime> weekDates) {
    return habits.isEmpty
        ? _buildEmptyState(context)
        : ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) => _buildHabitRow(
              context,
              habits[index],
              index,
              weekDates,
            ),
          );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes hábitos creados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Crea tu primer hábito con el botón +!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitRow(BuildContext context, Habit habit, int index, List<DateTime> weekDates) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildHabitNumber(context, habit, index),
          const SizedBox(width: 8),
          ..._buildDayCells(context, habit, weekDates),
        ],
      ),
    );
  }

  Widget _buildHabitNumber(BuildContext context, Habit habit, int index) {
    return GestureDetector(
      onLongPress: () => onDelete(habit.id!),
      child: Container(
        width: 42,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
      final canEdit = isToday;

      // Auto-skip logic: días pasados sin entrada se consideran skipped
      final displayStatus = (isPastDate && entry == null) 
          ? HabitStatus.skipped 
          : status;

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: GestureDetector(
            onTap: canEdit ? () => onToggle(habit.id!, date, status) : null,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: HabitStatusColor.getColor(displayStatus).withOpacity(
                  canEdit ? 1.0 : 0.7
                ),
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
              ),
              child: Center(
                child: HabitStatusIcon(
                  status: displayStatus, 
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
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