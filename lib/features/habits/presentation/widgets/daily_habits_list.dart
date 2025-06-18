// lib/features/habits/presentation/widgets/daily_habits_list.dart - SIN CARDS ANIDADOS
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con padding
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
                Text(
                  '${habits.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Lista de hábitos sin padding
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
                          onTap: () => onToggle(habit.id!, status),
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
                                color: HabitStatusColor.getBorderColor(status),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
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
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: HabitStatusColor.getBorderColor(status),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: status != HabitStatus.pending 
                                        ? HabitStatusColor.getColor(status)
                                        : null,
                                  ),
                                  child: Center(
                                    child: HabitStatusIcon(status: status, size: 16),
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
        ],
      ),
    );
  }
}