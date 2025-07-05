import 'package:flutter/material.dart';
import 'package:habitiurs/features/habits/domain/entities/habit.dart';
import 'package:habitiurs/features/habits/domain/entities/habit_entry.dart';
import 'package:habitiurs/shared/enums/habit_status.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import 'package:habitiurs/core/di/injection_container.dart';
import 'package:habitiurs/features/habits/domain/repositories/habit_repository.dart';

// Reusable components from WeeklyGrid
class _WallpaperHabitNumber extends StatelessWidget {
  final int number;

  const _WallpaperHabitNumber({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
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

class _WallpaperDayColumn extends StatelessWidget {
  final String dayName;
  final int dayNumber;
  final bool isToday;

  const _WallpaperDayColumn({
    required this.dayName,
    required this.dayNumber,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              fontSize: 9,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              color: isToday ? primaryColor : Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: isToday ? primaryColor : Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _WallpaperStatusCell extends StatelessWidget {
  final int habitId;
  final DateTime date;
  final List<HabitEntry> weekEntries;

  const _WallpaperStatusCell({
    required this.habitId,
    required this.date,
    required this.weekEntries,
  });

  HabitEntry? _findEntryForDate() {
    for (final entry in weekEntries) {
      if (entry.habitId == habitId && AppDateUtils.isSameDay(entry.date, date)) {
        return entry;
      }
    }
    return null;
  }

  Color _getCellColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[500]!;
      case HabitStatus.skipped:
        return Colors.red[400]!;
      case HabitStatus.pending:
        return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _findEntryForDate();
    final status = entry?.status ?? HabitStatus.pending;
    final isToday = AppDateUtils.isToday(date);
    final isPastDate = AppDateUtils.isPastDate(date);

    // Para el wallpaper, si es una fecha pasada y no hay entrada, se considera omitido
    final displayStatus = (isPastDate && entry == null)
        ? HabitStatus.skipped
        : status;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: _getCellColor(displayStatus).withOpacity(0.8), // Un poco transparente para el wallpaper
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                width: 2,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WeeklyWallpaperWidget extends StatefulWidget {
  const WeeklyWallpaperWidget({super.key});

  @override
  State<WeeklyWallpaperWidget> createState() => _WeeklyWallpaperWidgetState();
}

class _WeeklyWallpaperWidgetState extends State<WeeklyWallpaperWidget> {
  List<Habit> _habits = [];
  List<HabitEntry> _weekEntries = [];
  DateTime _weekStart = AppDateUtils.getStartOfWeek(DateTime.now());
  bool _isLoading = true;
  String? _error;
  final HabitRepository _habitRepository = InjectionContainer().habitRepository;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final habits = await _habitRepository.getAllHabits();
      final now = DateTime.now();
      final weekStart = AppDateUtils.getStartOfWeek(now);
      final weekEntries = await _habitRepository.getHabitEntriesForWeek(weekStart);

      setState(() {
        _habits = habits;
        _weekEntries = weekEntries;
        _weekStart = weekStart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando datos semanales: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = AppDateUtils.getWeekDates(_weekStart);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_habits.isEmpty) {
      return const Center(
        child: Text(
          'No hay hábitos configurados para la vista semanal.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Semanal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 0, 4), // Alineado con el _HabitNumber
            child: Row(
              children: AppDateUtils.weekDayNames.asMap().entries.map((entry) {
                final index = entry.key;
                final dayName = entry.value;
                final date = weekDates[index];
                final isToday = AppDateUtils.isToday(date);
                return Expanded(
                  child: _WallpaperDayColumn(
                    dayName: dayName,
                    dayNumber: date.day,
                    isToday: isToday,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Column(
              children: _habits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _habits.length - 1 ? 0 : 4,
                    ),
                    child: Row(
                      children: [
                        _WallpaperHabitNumber(number: index + 1),
                        const SizedBox(width: 4),
                        ...weekDates.map((date) => Expanded(
                              child: _WallpaperStatusCell(
                                habitId: habit.id!,
                                date: date,
                                weekEntries: _weekEntries,
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}