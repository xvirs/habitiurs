// lib/features/habits/presentation/widgets/habit_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';
import '../../../../shared/enums/habit_status.dart';
import 'habit_status_styles.dart';

/// Callback definitions para mejor legibilidad
typedef OnHabitToggleCallback =
    void Function(int habitId, HabitStatus currentStatus);
typedef OnHabitDeleteCallback = void Function(int habitId, String habitName);

class HabitTile extends StatelessWidget {
  final Habit habit;
  final int index;
  final HabitStatus status;
  final OnHabitToggleCallback onToggle;
  final OnHabitDeleteCallback
  onDelete; // Mantenemos por compatibilidad pero no se usa

  const HabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.status,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onToggle(habit.id!, status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: HabitStatusStyles.buildTileDecoration(status),
          child: Row(
            children: [
              _HabitNumber(number: index + 1), // Sin onLongPress
              const SizedBox(width: 12),
              Expanded(child: _HabitName(name: habit.name, status: status)),
              _StatusToggle(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitNumber extends StatelessWidget {
  final int number;

  const _HabitNumber({required this.number});

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

class _HabitName extends StatelessWidget {
  final String name;
  final HabitStatus status;

  const _HabitName({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontWeight: FontWeight.w500);

    return Text(
      name,
      style: HabitStatusStyles.buildHabitNameStyle(status, baseStyle),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final HabitStatus status;

  const _StatusToggle({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: HabitStatusStyles.buildToggleDecoration(status),
      child: Center(child: HabitStatusStyles.buildStatusIcon(status)),
    );
  }
}
