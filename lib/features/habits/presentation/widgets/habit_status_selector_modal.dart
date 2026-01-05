import 'package:flutter/material.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../core/service/vibration_service.dart';

class HabitStatusSelectorModal extends StatelessWidget {
  final String habitName;
  final HabitStatus currentStatus;
  final Function(HabitStatus) onStatusSelected;

  const HabitStatusSelectorModal({
    super.key,
    required this.habitName,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  static Future<HabitStatus?> show(
    BuildContext context, {
    required String habitName,
    required HabitStatus currentStatus,
  }) async {
    await VibrationService.medium();

    if (!context.mounted) return null;

    return showDialog<HabitStatus>(
      context: context,
      builder: (context) => HabitStatusSelectorModal(
        habitName: habitName,
        currentStatus: currentStatus,
        onStatusSelected: (status) {
          Navigator.of(context).pop(status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(76),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.edit_calendar,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modificar día pasado',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo completaste este hábito ese día?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(76),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"$habitName"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Completado button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                VibrationService.success();
                onStatusSelected(HabitStatus.completed);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green[500],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('Completado'),
            ),
          ),
          const SizedBox(height: 8),
          // Saltado button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                VibrationService.warning();
                onStatusSelected(HabitStatus.skipped);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.cancel),
              label: const Text('Saltado'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            VibrationService.selection();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
