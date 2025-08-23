// lib/features/habits/presentation/widgets/delete_confirmation_dialog.dart
import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Eliminar hábito'),
      content: const Text(
        '¿Eliminar este hábito? Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}