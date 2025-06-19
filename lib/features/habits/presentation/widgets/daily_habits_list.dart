// lib/features/habits/presentation/widgets/daily_habits_list.dart - LIMPIO CON BOTÓN +
import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../widgets/habit_status_icon.dart';
import '../../../../shared/enums/habit_status.dart';

class DailyHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitEntry> todayEntries;
  final Function(int habitId, HabitStatus currentStatus) onToggle;
  final Function(int habitId) onDelete;
  final VoidCallback onAdd; // SIMPLIFICADO: Solo callback sin parámetros

  const DailyHabitsList({
    super.key,
    required this.habits,
    required this.todayEntries,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón + a la derecha
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
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
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hábitos de hoy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón + reemplazando el número de hábitos
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de hábitos
          Expanded(
            child: habits.isEmpty
                ? _buildEmptyState(context)
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];

                        HabitEntry? habitEntry;
                        try {
                          habitEntry = todayEntries.firstWhere(
                            (e) => e.habitId == habit.id,
                          );
                        } catch (e) {
                          habitEntry = null;
                        }

                        final status = habitEntry?.status ?? HabitStatus.pending;

                        return GestureDetector(
                          onTap: () => _handleToggle(habit.id!, status),
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: index == habits.length - 1 ? 0 : 8,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              index == habits.length - 1 ? 16 : 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getSimplifiedBorderColor(status),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: status == HabitStatus.completed 
                                  ? Colors.green.withOpacity(0.05)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onLongPress: () => onDelete(habit.id!),
                                  child: Container(
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    habit.name,
                                    style: TextStyle(
                                      decoration: status == HabitStatus.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: status == HabitStatus.completed
                                          ? Colors.grey[600]
                                          : null,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _getToggleBackgroundColor(status),
                                    border: Border.all(
                                      color: _getToggleBorderColor(status),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: _getToggleIcon(status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleToggle(int habitId, HabitStatus currentStatus) {
    onToggle(habitId, currentStatus);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_task,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes hábitos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar tu primer hábito',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Métodos de colores (sin cambios)
  Color _getSimplifiedBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green.withOpacity(0.3);
      case HabitStatus.pending:
        return Colors.grey.withOpacity(0.3);
      case HabitStatus.skipped:
        return Colors.red.withOpacity(0.3);
    }
  }

  Color _getToggleBackgroundColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[500]!;
      case HabitStatus.pending:
        return Colors.grey[100]!;
      case HabitStatus.skipped:
        return Colors.red[400]!;
    }
  }

  Color _getToggleBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[600]!;
      case HabitStatus.pending:
        return Colors.grey[400]!;
      case HabitStatus.skipped:
        return Colors.red[500]!;
    }
  }

  Widget _getToggleIcon(HabitStatus status) {
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
}