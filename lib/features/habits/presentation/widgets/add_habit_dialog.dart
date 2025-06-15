import 'package:flutter/material.dart';

class AddHabitDialog extends StatefulWidget {
  final Function(String) onAdd;

  const AddHabitDialog({super.key, required this.onAdd});

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Hábito'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del hábito',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un nombre';
            }
            if (value.trim().length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
          autofocus: true,
          onFieldSubmitted: (_) => _addHabit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _addHabit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _addHabit() {
    if (_formKey.currentState!.validate()) {
      widget.onAdd(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }
}