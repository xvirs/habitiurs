// lib/features/habits/presentation/widgets/habit_tile.dart
import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_appearance.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/theme/app_theme.dart';
import 'habit_status_styles.dart';

/// Callback definitions para mejor legibilidad
typedef OnHabitToggleCallback =
    void Function(int habitId, HabitStatus currentStatus);
typedef OnHabitDeleteCallback = void Function(int habitId, String habitName);
typedef OnHabitEditCallback = void Function(Habit habit);

class HabitTile extends StatelessWidget {
  final Habit habit;
  final int index;
  final HabitStatus status;
  final OnHabitToggleCallback onToggle;
  final OnHabitDeleteCallback
  onDelete; // Mantenemos por compatibilidad pero no se usa
  final OnHabitEditCallback? onEdit;

  /// Días consecutivos completados (0 = sin racha).
  final int streak;

  const HabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.status,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Un hábito programado solo ciertos días no se puede MARCAR los días que no
    // toca (pero sí editar con long-press y borrar con swipe). Se muestra
    // atenuado y con un indicador de "no programado hoy".
    final scheduledToday = habit.isScheduledOn(DateTime.now());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            scheduledToday
                ? () => onToggle(habit.id!, status)
                : () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Este hábito no está programado para hoy',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                },
        onLongPress: onEdit == null ? null : () => onEdit!(habit),
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: scheduledToday ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: HabitStatusStyles.buildTileDecoration(context, status),
            child: Row(
              children: [
                _HabitBadge(habit: habit),
                const SizedBox(width: 12),
                Expanded(child: _HabitName(name: habit.name, status: status)),
                if (streak > 1) _StreakBadge(streak: streak),
                scheduledToday
                    ? _StatusToggle(status: status)
                    : const _NotScheduledIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Racha del hábito. Solo desde 2 días: con 1 no hay "racha" que cuidar.
class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador para hábitos no programados hoy (no se pueden marcar).
class _NotScheduledIndicator extends StatelessWidget {
  const _NotScheduledIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Icon(
          Icons.event_busy_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _HabitBadge extends StatelessWidget {
  final Habit habit;

  const _HabitBadge({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Color(habit.colorValue),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          HabitAppearance.iconFor(habit.iconKey),
          color: Colors.white,
          size: 16,
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
      style: HabitStatusStyles.buildHabitNameStyle(context, status, baseStyle),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final HabitStatus status;

  const _StatusToggle({required this.status});

  @override
  Widget build(BuildContext context) {
    // Círculo-check (misma anatomía que Misiones). El '+' anterior se
    // confundía con "agregar".
    final theme = Theme.of(context);
    final (icon, color) = switch (status) {
      HabitStatus.completed => (
        Icons.check_circle,
        AppColors.completed(context),
      ),
      HabitStatus.skipped => (
        Icons.cancel_outlined,
        AppColors.skipped(context).withValues(alpha: 0.8),
      ),
      HabitStatus.pending => (
        Icons.radio_button_unchecked,
        theme.colorScheme.outline,
      ),
    };
    return SizedBox(
      width: 32,
      height: 32,
      child: Icon(icon, size: 28, color: color),
    );
  }
}
