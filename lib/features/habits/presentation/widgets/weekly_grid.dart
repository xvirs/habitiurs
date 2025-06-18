// lib/features/habits/presentation/widgets/weekly_grid.dart - DISEÑO DELICADO
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

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header simple
            Row(
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
            ),
            const SizedBox(height: 16),
            _buildHeader(context, weekDates),
            const SizedBox(height: 12),
            Expanded(
              child: _buildGrid(context, weekDates),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekRange(List<DateTime> weekDates) {
    final start = weekDates.first;
    final end = weekDates.last;
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  Widget _buildHeader(BuildContext context, List<DateTime> weekDates) {
    return Row(
      children: [
        const SizedBox(width: 36),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[100]!,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildHabitNumber(context, habit, index),
          const SizedBox(width: 6),
          ..._buildDayCells(context, habit, weekDates),
        ],
      ),
    );
  }

  Widget _buildHabitNumber(BuildContext context, Habit habit, int index) {
    return GestureDetector(
      onLongPress: () => onDelete(habit.id!),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
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

      final displayStatus = (isPastDate && entry == null) 
          ? HabitStatus.skipped 
          : status;

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          child: GestureDetector(
            onTap: canEdit ? () => onToggle(habit.id!, date, status) : null,
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: displayStatus != HabitStatus.pending 
                    ? _getDelicateColor(displayStatus, isToday)
                    : null,
                border: Border.all(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                      : _getDelicateBorderColor(displayStatus),
                  width: isToday ? 1.5 : 0.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: HabitStatusIcon(
                  status: displayStatus, 
                  size: 10,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getDelicateColor(HabitStatus status, bool isToday) {
    final opacity = isToday ? 0.4 : 0.2;
    
    switch (status) {
      case HabitStatus.completed:
        return Colors.green.withOpacity(opacity);
      case HabitStatus.skipped:
        return Colors.red.withOpacity(opacity);
      case HabitStatus.pending:
        return Colors.transparent;
    }
  }

  Color _getDelicateBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green.withOpacity(0.3);
      case HabitStatus.skipped:
        return Colors.red.withOpacity(0.3);
      case HabitStatus.pending:
        return Colors.grey.withOpacity(0.2);
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