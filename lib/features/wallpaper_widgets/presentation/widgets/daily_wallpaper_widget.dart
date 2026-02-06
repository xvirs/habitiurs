import 'package:flutter/material.dart';
import 'package:habitiurs/features/habits/domain/entities/habit.dart';
import 'package:habitiurs/shared/enums/habit_status.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import 'package:habitiurs/core/di/injection_container.dart';
import 'package:habitiurs/features/habits/domain/repositories/habit_repository.dart';

// Reusable components from HabitTile
// Note: These are simplified for display only, no onTap/onLongPress callbacks
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

class _WallpaperHabitName extends StatelessWidget {
  final String name;
  final HabitStatus status;

  const _WallpaperHabitName({
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: TextStyle(
        decoration: status == HabitStatus.completed
            ? TextDecoration.lineThrough
            : null,
        color: status == HabitStatus.completed
            ? Colors.grey[600]
            : Colors.black87, // Color predeterminado para el texto
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }
}

class _WallpaperStatusToggle extends StatelessWidget {
  final HabitStatus status;

  const _WallpaperStatusToggle({required this.status});

  Color _getBackgroundColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[500]!;
      case HabitStatus.pending:
        return Colors.grey[100]!;
      case HabitStatus.skipped:
        return Colors.red[400]!;
    }
  }

  Color _getBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[600]!;
      case HabitStatus.pending:
        return Colors.grey[400]!;
      case HabitStatus.skipped:
        return Colors.red[500]!;
    }
  }

  Widget _getIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return const Icon(
          Icons.check,
          color: Colors.white,
          size: 18,
        );
      case HabitStatus.pending:
        return Icon(
          Icons.add,
          color: Colors.grey[600],
          size: 18,
        );
      case HabitStatus.skipped:
        return const Icon(
          Icons.close,
          color: Colors.white,
          size: 18,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _getBackgroundColor(status),
        border: Border.all(
          color: _getBorderColor(status),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: _getIcon(status),
      ),
    );
  }
}

class DailyWallpaperWidget extends StatefulWidget {
  const DailyWallpaperWidget({super.key});

  @override
  State<DailyWallpaperWidget> createState() => _DailyWallpaperWidgetState();
}

class _DailyWallpaperWidgetState extends State<DailyWallpaperWidget> {
  List<Habit> _habits = [];
  Map<int, HabitStatus> _todayEntriesMap = {};
  bool _isLoading = true;
  String? _error;
  final HabitRepository _habitRepository = InjectionContainer().habitRepository;

  @override
  void initState() {
    super.initState();
    _loadDailyHabits();
  }

  Future<void> _loadDailyHabits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final habits = await _habitRepository.getAllHabits();
      final now = DateTime.now();
      final allEntries = await _habitRepository.getHabitEntriesForDateRange(
        AppDateUtils.getStartOfDay(now.subtract(const Duration(days: 1))), // Sólo necesitamos hoy o ayer para el "skipped"
        AppDateUtils.getEndOfDay(now),
      );

      final Map<int, HabitStatus> todayEntries = {};
      final today = AppDateUtils.getStartOfDay(now);

      for (final habit in habits) {
        final entryForHabitToday = allEntries.firstWhereOrNull(
          (entry) => entry.habitId == habit.id && AppDateUtils.isSameDay(entry.date, today),
        );

        if (entryForHabitToday != null) {
          todayEntries[habit.id!] = entryForHabitToday.status;
        } else {
          // Si no hay entrada para hoy, y el hábito es de un día anterior,
          // se podría considerar 'skipped' por defecto para el wallpaper
          // Esto es una simplificación ya que no hay interacción para cambiarlo
          if (AppDateUtils.isPastDate(today)) {
             todayEntries[habit.id!] = HabitStatus.skipped;
          } else {
             todayEntries[habit.id!] = HabitStatus.pending;
          }
        }
      }

      setState(() {
        _habits = habits;
        _todayEntriesMap = todayEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando hábitos diarios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'No hay hábitos configurados.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hábitos de Hoy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final status = _todayEntriesMap[habit.id!] ?? HabitStatus.pending;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      _WallpaperHabitNumber(number: index + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _WallpaperHabitName(
                          name: habit.name,
                          status: status,
                        ),
                      ),
                      _WallpaperStatusToggle(status: status),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension ListX<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}