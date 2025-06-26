import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';
import '../../../../shared/enums/habit_status.dart';
// Eliminadas las importaciones de habit_status_icon.dart y habit_status_styles.dart

class HabitTile extends StatelessWidget {
  final Habit habit;
  final int index;
  final HabitStatus status;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

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
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _getBorderColor(status),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: status == HabitStatus.completed
                ? Colors.green.withOpacity(0.05)
                : null,
          ),
          child: Row(
            children: [
              _HabitNumber(
                number: index + 1,
                onLongPress: onDelete,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HabitName(
                  name: habit.name,
                  status: status,
                ),
              ),
              _StatusToggle(status: status),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => Colors.green.withOpacity(0.3),
      HabitStatus.pending => Colors.grey.withOpacity(0.3),
      HabitStatus.skipped => Colors.red.withOpacity(0.3),
    };
  }
}

class _HabitNumber extends StatelessWidget {
  final int number;
  final VoidCallback onLongPress;

  const _HabitNumber({
    required this.number,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
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
      ),
    );
  }
}

class _HabitName extends StatelessWidget {
  final String name;
  final HabitStatus status;

  const _HabitName({
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
            : null,
        fontWeight: FontWeight.w500,
      ),
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

  Color _getBackgroundColor(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => Colors.green[500]!,
      HabitStatus.pending => Colors.grey[100]!,
      HabitStatus.skipped => Colors.red[400]!,
    };
  }

  Color _getBorderColor(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => Colors.green[600]!,
      HabitStatus.pending => Colors.grey[400]!,
      HabitStatus.skipped => Colors.red[500]!,
    };
  }

  Widget _getIcon(HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => const Icon(
          Icons.check,
          color: Colors.white,
          size: 18,
        ),
      HabitStatus.pending => Icon(
          Icons.add,
          color: Colors.grey[600],
          size: 18,
        ),
      HabitStatus.skipped => const Icon(
          Icons.close,
          color: Colors.white,
          size: 18,
        ),
    };
  }
}
