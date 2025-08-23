// lib/features/habits/presentation/widgets/weekly_grid.dart
import 'package:flutter/material.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';

class WeeklyGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitEntry> weekEntries;
  final DateTime weekStart;
  final bool isLoading;

  const WeeklyGrid({
    super.key,
    required this.habits,
    required this.weekEntries,
    required this.weekStart,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final weekDates = AppDateUtils.getWeekDates(weekStart);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(weekDates: weekDates),
          _DaysHeader(weekDates: weekDates),
          Expanded(child: _buildBody(weekDates)),
        ],
      ),
    );
  }

  Widget _buildBody(List<DateTime> weekDates) {
    if (isLoading) {
      return const _LoadingState();
    }
    
    if (habits.isEmpty) {
      return const _EmptyState();
    }
    
    return _HabitsGrid(
      habits: habits,
      weekDates: weekDates,
      weekEntries: weekEntries,
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final List<DateTime> weekDates;

  const _HeaderSection({required this.weekDates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _VerticalAccent(color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Icon(
            Icons.view_week,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vista semanal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _DateRange(
            startDay: weekDates.first.day,
            endDay: weekDates.last.day,
          ),
        ],
      ),
    );
  }
}

class _VerticalAccent extends StatelessWidget {
  final Color color;

  const _VerticalAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DateRange extends StatelessWidget {
  final int startDay;
  final int endDay;

  const _DateRange({
    required this.startDay,
    required this.endDay,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$startDay - $endDay',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DaysHeader extends StatelessWidget {
  final List<DateTime> weekDates;

  const _DaysHeader({required this.weekDates});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 28), // Space for habit numbers
          ...weekDates.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            final dayName = AppDateUtils.weekDayNames[index];
            final isToday = AppDateUtils.isToday(date);

            return Expanded(
              child: _DayColumn(
                dayName: dayName,
                dayNumber: date.day,
                isToday: isToday,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final String dayName;
  final int dayNumber;
  final bool isToday;

  const _DayColumn({
    required this.dayName,
    required this.dayNumber,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: isToday
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withOpacity(0.8),
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
              color: isToday ? primaryColor : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: isToday ? primaryColor : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<DateTime> weekDates;
  final List<HabitEntry> weekEntries;

  const _HabitsGrid({
    required this.habits,
    required this.weekDates,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: habits.asMap().entries.map((entry) {
          final index = entry.key;
          final habit = entry.value;
          final isLast = index == habits.length - 1;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
              child: _HabitRow(
                habit: habit,
                index: index,
                weekDates: weekDates,
                weekEntries: weekEntries,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final int index;
  final List<DateTime> weekDates;
  final List<HabitEntry> weekEntries;

  const _HabitRow({
    required this.habit,
    required this.index,
    required this.weekDates,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HabitNumber(
          number: index + 1,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        ...weekDates.map((date) => Expanded(
          child: _StatusCell(
            habitId: habit.id!,
            date: date,
            weekEntries: weekEntries,
          ),
        )),
      ],
    );
  }
}

class _HabitNumber extends StatelessWidget {
  final int number;
  final Color color;

  const _HabitNumber({
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final int habitId;
  final DateTime date;
  final List<HabitEntry> weekEntries;

  const _StatusCell({
    required this.habitId,
    required this.date,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    final entry = _findEntry();
    final status = _getDisplayStatus(entry);
    final isToday = AppDateUtils.isToday(date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  HabitEntry? _findEntry() {
    for (final entry in weekEntries) {
      if (entry.habitId == habitId && 
          AppDateUtils.isSameDay(entry.date, date)) {
        return entry;
      }
    }
    return null;
  }

  HabitStatus _getDisplayStatus(HabitEntry? entry) {
    if (entry != null) return entry.status;
    if (AppDateUtils.isPastDate(date)) return HabitStatus.skipped;
    return HabitStatus.pending;
  }

  Color _getStatusColor(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => Colors.green[500]!,
      HabitStatus.skipped => Colors.red[400]!,
      HabitStatus.pending => Colors.grey[200]!,
    };
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_week,
              size: 40,
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes hábitos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer hábito para ver el progreso semanal aquí.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}