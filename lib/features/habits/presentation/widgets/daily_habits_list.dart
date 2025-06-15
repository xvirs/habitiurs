// lib/features/habits/presentation/widgets/daily_habits_list.dart - UI MEJORADA
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

  const DailyHabitsList({
    super.key,
    required this.habits,
    required this.todayEntries,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con estilo mejorado
          Text(
            'Hábitos de hoy',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de hábitos con diseño mejorado
          Expanded(
            child: habits.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habit = habits[index];

                      // Buscar entrada para este hábito hoy
                      HabitEntry? habitEntry;
                      try {
                        habitEntry = todayEntries.firstWhere(
                          (e) => e.habitId == habit.id,
                        );
                      } catch (e) {
                        habitEntry = null;
                      }

                      final status = habitEntry?.status ?? HabitStatus.pending;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: GestureDetector(
                            onLongPress: () => onDelete(habit.id!),
                            child: Container(
                              width: 36,
                              height: 36,
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
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            habit.name,
                            style: TextStyle(
                              decoration: status == HabitStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: _getTextColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () => onToggle(habit.id!, status),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: HabitStatusColor.getColor(status),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: HabitStatusIcon(status: status, size: 18),
                              ),
                            ),
                          ),
                          onTap: () => onToggle(habit.id!, status),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes hábitos para realizar hoy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar tu primer hábito',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color? _getTextColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.grey[600];
      case HabitStatus.skipped:
        return Colors.red[400];
      case HabitStatus.pending:
        return null;
    }
  }
}