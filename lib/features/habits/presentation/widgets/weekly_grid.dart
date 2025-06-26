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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _HeaderSection(weekDates: weekDates),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _DaysHeader(weekDates: weekDates),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: habits.isEmpty
                  ? const _EmptyGridState()
                  : _StackedHabitsGrid(
                      habits: habits,
                      weekDates: weekDates,
                      weekEntries: weekEntries,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final List<DateTime> weekDates;

  const _HeaderSection({required this.weekDates});

  @override
  Widget build(BuildContext context) {
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
        _DateRange(
          startDay: weekDates.first.day,
          endDay: weekDates.last.day,
        ),
      ],
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
    return Row(
      children: [
        const SizedBox(width: 28),
        ...AppDateUtils.weekDayNames.asMap().entries.map((entry) {
          final index = entry.key;
          final dayName = entry.value;
          final date = weekDates[index];
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
    final primaryColor = Theme.of(context).colorScheme.primary;

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
              color: isToday ? primaryColor : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: isToday ? primaryColor : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedHabitsGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<DateTime> weekDates;
  final List<HabitEntry> weekEntries;

  const _StackedHabitsGrid({
    required this.habits,
    required this.weekDates,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: habits.asMap().entries.map((entry) {
        final index = entry.key;
        final habit = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: index == habits.length - 1 ? 0 : 4,
            ),
            child: _HabitRow(
              habit: habit,
              index: index,
              weekDates: weekDates,
              weekEntries: weekEntries,
            ),
          ),
        );
      }).toList(),
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
    final entry = _findEntryForDate();
    final status = entry?.status ?? HabitStatus.pending;
    final isToday = AppDateUtils.isToday(date);
    final isPastDate = AppDateUtils.isPastDate(date);

    final displayStatus = (isPastDate && entry == null)
        ? HabitStatus.skipped
        : status;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getCellColor(displayStatus),
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

  HabitEntry? _findEntryForDate() {
    for (final entry in weekEntries) {
      if (entry.habitId == habitId && AppDateUtils.isSameDay(entry.date, date)) {
        return entry;
      }
    }
    return null;
  }

  Color _getCellColor(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => Colors.green[500]!,
      HabitStatus.skipped => Colors.red[400]!,
      HabitStatus.pending => Colors.grey[200]!,
    };
  }
}

class _EmptyGridState extends StatelessWidget {
  const _EmptyGridState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer hábito para ver el progreso semanal aquí.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
