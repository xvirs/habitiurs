import 'package:flutter/material.dart';

import '../../domain/entities/mission.dart';

/// Resultado del formulario de misión (creación o edición).
class MissionFormResult {
  final String title;
  final String? note;
  final DateTime? dueDate;

  const MissionFormResult({required this.title, this.note, this.dueDate});
}

class AddMissionBottomSheet extends StatefulWidget {
  final void Function(MissionFormResult) onSubmit;

  /// Si no es null, el sheet edita esta misión en vez de crear una nueva.
  final Mission? initial;

  const AddMissionBottomSheet({
    super.key,
    required this.onSubmit,
    this.initial,
  });

  static void show(
    BuildContext context, {
    required void Function(MissionFormResult) onSubmit,
    Mission? initial,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddMissionBottomSheet(onSubmit: onSubmit, initial: initial),
    );
  }

  @override
  State<AddMissionBottomSheet> createState() => _AddMissionBottomSheetState();
}

class _AddMissionBottomSheetState extends State<AddMissionBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  final _formKey = GlobalKey<FormState>();
  DateTime? _dueDate;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _noteController = TextEditingController(text: widget.initial?.note ?? '');
    _dueDate = widget.initial?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha límite',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final note = _noteController.text.trim();
    widget.onSubmit(
      MissionFormResult(
        title: _titleController.text.trim(),
        note: note.isEmpty ? null : note,
        dueDate: _dueDate,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomSafe + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Editar misión' : 'Nueva misión',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Ej: Ir al dentista',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Escribe al menos 3 caracteres';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              maxLength: 80,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 200,
            ),
            const SizedBox(height: 4),
            _DueDateRow(
              dueDate: _dueDate,
              onPick: _pickDate,
              onClear: () => setState(() => _dueDate = null),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: Icon(_isEditing ? Icons.check : Icons.add, size: 18),
                    label: Text(_isEditing ? 'Guardar' : 'Crear misión'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DueDateRow extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DueDateRow({
    required this.dueDate,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = dueDate != null;

    return Row(
      children: [
        Icon(
          Icons.event_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            has ? 'Fecha límite: ${_formatDate(dueDate!)}' : 'Sin fecha límite',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (has)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: 'Quitar fecha',
          ),
        TextButton(onPressed: onPick, child: Text(has ? 'Cambiar' : 'Añadir')),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
