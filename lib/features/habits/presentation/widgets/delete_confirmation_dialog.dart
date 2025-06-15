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
    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: Theme.of(context).colorScheme.error,
        size: 32,
      ),
      title: const Text('Eliminar Hábito'),
      content: const Text(
        '¿Estás seguro de que quieres eliminar este hábito?\n\n'
        'Esta acción no se puede deshacer y se perderán todos los datos relacionados.',
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
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}