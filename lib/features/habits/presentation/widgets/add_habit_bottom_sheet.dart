import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_evaluation_cubit.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_evaluation_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_appearance.dart';

/// Resultado del formulario de hábito (creación o edición).
class HabitFormResult {
  final String name;
  final int colorValue;
  final String iconKey;
  final List<int> weekdays;
  final String? reminderTime;

  const HabitFormResult({
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.weekdays,
    this.reminderTime,
  });
}

class AddHabitBottomSheet extends StatefulWidget {
  final Function(HabitFormResult) onSubmit;

  /// Si no es null, el sheet edita este hábito en vez de crear uno nuevo.
  final Habit? initial;
  final VoidCallback? onArchive;

  const AddHabitBottomSheet({
    super.key,
    required this.onSubmit,
    this.initial,
    this.onArchive,
  });

  @override
  State<AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();

  static void show(
    BuildContext context, {
    required Function(HabitFormResult) onSubmit,
    Habit? initial,
    VoidCallback? onArchive,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => BlocProvider<HabitEvaluationCubit>(
        create: (ctx) => InjectionContainer().habitEvaluationCubit,
        child: _AdaptiveBottomSheet(
          child: AddHabitBottomSheet(
            onSubmit: onSubmit,
            initial: initial,
            onArchive: onArchive,
          ),
        ),
      ),
    );
  }
}

class _AddHabitBottomSheetState extends State<AddHabitBottomSheet> {
  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;
  late final FocusNode _focusNode;

  static const int _minHabitLength = 3;

  late int _selectedColor;
  late String _selectedIcon;
  late Set<int> _selectedWeekdays;
  TimeOfDay? _reminderTime;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _controller.addListener(_onTextChangedListener);
  }

  void _initializeControllers() {
    final initial = widget.initial;
    _controller = TextEditingController(text: initial?.name ?? '');
    _formKey = GlobalKey<FormState>();
    _focusNode = FocusNode();
    _selectedColor = initial?.colorValue ?? Habit.defaultColor;
    _selectedIcon = initial?.iconKey ?? Habit.defaultIcon;
    _selectedWeekdays = Set<int>.from(initial?.weekdays ?? Habit.allWeekdays);
    _reminderTime = _parseReminder(initial?.reminderTime);
  }

  static TimeOfDay? _parseReminder(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String? get _reminderAsString => _reminderTime == null
      ? null
      : '${_reminderTime!.hour.toString().padLeft(2, '0')}:'
          '${_reminderTime!.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _controller.removeListener(_onTextChangedListener);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChangedListener() {
    final currentCubitState = context.read<HabitEvaluationCubit>().state;
    
    // Si la evaluación está mostrándose (Success, Loading o Error) y el texto cambia,
    // o si el texto es muy corto, ocultarla para permitir re-evaluar o limpiar.
    if (currentCubitState is HabitEvaluationSuccess ||
        currentCubitState is HabitEvaluationError ||
        currentCubitState is HabitEvaluationLoading) {
      if (_controller.text.trim().length < _minHabitLength) {
        // Si el texto es muy corto, simplemente ocultamos.
        context.read<HabitEvaluationCubit>().hideEvaluation();
      } else if (currentCubitState is! HabitEvaluationLoading) {
        // Si no está cargando y el texto es lo suficientemente largo,
        // pero un resultado ya está visible, ocúltalo para permitir re-evaluar.
        // Esto cubre el caso de editar un resultado ya existente.
        context.read<HabitEvaluationCubit>().hideEvaluation();
      }
    }
    // IMPORTANTE: Llamar setState para que la UI se reconstruya y
    // `_canAddHabit` se reevalúe, actualizando el estado de los botones.
    setState(() {});
  }

  void _evaluateHabit() {
    if (!_canAddHabit) return;
    context.read<HabitEvaluationCubit>().evaluateHabit(_controller.text.trim());
  }

  void _hideEvaluation() {
    context.read<HabitEvaluationCubit>().hideEvaluation();
  }

  void _addHabit() {
    if (_formKey.currentState?.validate() ?? false) {
      _focusNode.unfocus();
      final days = _selectedWeekdays.toList()..sort();
      widget.onSubmit(HabitFormResult(
        name: _controller.text.trim(),
        colorValue: _selectedColor,
        iconKey: _selectedIcon,
        weekdays: days.isEmpty ? Habit.allWeekdays : days,
        reminderTime: _reminderAsString,
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  bool get _canAddHabit =>
      _controller.text.trim().length >= _minHabitLength &&
      _selectedWeekdays.isNotEmpty;

  /// Cierra el teclado sin enviar el formulario (al tocar fuera o "listo").
  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;

    return _BottomSheetContainer(
      child: GestureDetector(
        // Tocar cualquier zona vacía del sheet cierra el teclado.
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: BlocBuilder<HabitEvaluationCubit, HabitEvaluationState>(
          builder: (context, state) {
            bool showEvaluationSection = state is HabitEvaluationSuccess ||
                state is HabitEvaluationLoading ||
                state is HabitEvaluationError;
            bool isEvaluating = state is HabitEvaluationLoading;
            String evaluationText = '';
            if (state is HabitEvaluationSuccess) {
              evaluationText = state.evaluationText;
            }
            if (state is HabitEvaluationError) evaluationText = state.message;
            if (state is HabitEvaluationLoading) evaluationText = 'Analizando...';

            return _BottomSheetContent(
              hasKeyboard: hasKeyboard,
              formKey: _formKey,
              controller: _controller,
              focusNode: _focusNode,
              isEvaluating: isEvaluating,
              showEvaluation: showEvaluationSection,
              evaluationText: evaluationText,
              onEvaluate: _evaluateHabit,
              onHideEvaluation: _hideEvaluation,
              onAddHabit: _addHabit,
              onDismissKeyboard: _dismissKeyboard,
              onTextChanged: (value) {},
              canAddHabit: _canAddHabit,
              isEditing: _isEditing,
              onArchive: widget.onArchive,
              customization: _CustomizationSection(
              selectedColor: _selectedColor,
              selectedIcon: _selectedIcon,
              selectedWeekdays: _selectedWeekdays,
              reminderTime: _reminderTime,
              onColorChanged: (c) => setState(() => _selectedColor = c),
              onIconChanged: (i) => setState(() => _selectedIcon = i),
              onWeekdayToggled: (d) => setState(() {
                if (_selectedWeekdays.contains(d)) {
                  _selectedWeekdays.remove(d);
                } else {
                  _selectedWeekdays.add(d);
                }
              }),
              onPickReminder: _pickReminderTime,
              onClearReminder: () => setState(() => _reminderTime = null),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final Widget child;

  const _BottomSheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final bool hasKeyboard;
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEvaluating;
  final bool showEvaluation;
  final String evaluationText;
  final VoidCallback onEvaluate;
  final VoidCallback onHideEvaluation;
  final VoidCallback onAddHabit;
  final VoidCallback onDismissKeyboard;
  final ValueChanged<String> onTextChanged;
  final bool canAddHabit;
  final bool isEditing;
  final VoidCallback? onArchive;
  final Widget customization;

  const _BottomSheetContent({
    required this.hasKeyboard,
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.isEvaluating,
    required this.showEvaluation,
    required this.evaluationText,
    required this.onEvaluate,
    required this.onHideEvaluation,
    required this.onAddHabit,
    required this.onDismissKeyboard,
    required this.onTextChanged,
    required this.canAddHabit,
    required this.isEditing,
    required this.onArchive,
    required this.customization,
  });

  @override
  Widget build(BuildContext context) {
    // Respeta la barra de navegación / gestos del sistema en el borde inferior.
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomSafe),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(hasKeyboard: hasKeyboard, isEditing: isEditing),
                    const SizedBox(height: 12),
                    if (!isEditing) ...[
                      _InfoSection(
                        hasKeyboard: hasKeyboard,
                        showEvaluation: showEvaluation,
                        isEvaluating: isEvaluating,
                        evaluationText: evaluationText,
                        onClose: onHideEvaluation,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _HabitTextField(
                      controller: controller,
                      focusNode: focusNode,
                      hasKeyboard: hasKeyboard,
                      onChanged: onTextChanged,
                      // "Listo" en el teclado solo lo cierra; NO crea el hábito.
                      onSubmitted: onDismissKeyboard,
                      onClear: onHideEvaluation,
                    ),
                    const SizedBox(height: 10),
                    if (!isEditing)
                      _EvaluateButton(
                        hasKeyboard: hasKeyboard,
                        canEvaluate: canAddHabit && !isEvaluating,
                        onPressed: onEvaluate,
                      ),
                    const SizedBox(height: 12),
                    customization,
                    if (isEditing && onArchive != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onArchive!();
                        },
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('Archivar hábito'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ActionButtons(
              hasKeyboard: hasKeyboard,
              canAddHabit: canAddHabit,
              isEditing: isEditing,
              onCancel: () => Navigator.of(context).pop(),
              onAdd: onAddHabit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizationSection extends StatelessWidget {
  final int selectedColor;
  final String selectedIcon;
  final Set<int> selectedWeekdays;
  final TimeOfDay? reminderTime;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<int> onWeekdayToggled;
  final VoidCallback onPickReminder;
  final VoidCallback onClearReminder;

  const _CustomizationSection({
    required this.selectedColor,
    required this.selectedIcon,
    required this.selectedWeekdays,
    required this.reminderTime,
    required this.onColorChanged,
    required this.onIconChanged,
    required this.onWeekdayToggled,
    required this.onPickReminder,
    required this.onClearReminder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(theme, 'Días de la semana'),
        const SizedBox(height: 8),
        _WeekdaySelector(
          selected: selectedWeekdays,
          accentColor: Color(selectedColor),
          onToggled: onWeekdayToggled,
        ),
        const SizedBox(height: 14),
        _sectionLabel(theme, 'Color'),
        const SizedBox(height: 8),
        _ColorPicker(selected: selectedColor, onChanged: onColorChanged),
        const SizedBox(height: 14),
        _sectionLabel(theme, 'Icono'),
        const SizedBox(height: 8),
        _IconPicker(
          selected: selectedIcon,
          accentColor: Color(selectedColor),
          onChanged: onIconChanged,
        ),
        const SizedBox(height: 14),
        _ReminderRow(
          reminderTime: reminderTime,
          onPick: onPickReminder,
          onClear: onClearReminder,
        ),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  final Set<int> selected;
  final Color accentColor;
  final ValueChanged<int> onToggled;

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  const _WeekdaySelector({
    required this.selected,
    required this.accentColor,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isSelected = selected.contains(day);
        return GestureDetector(
          onTap: () => onToggled(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HabitAppearance.colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final colorValue = HabitAppearance.colors[index];
          final isSelected = colorValue == selected;
          return GestureDetector(
            onTap: () => onChanged(colorValue),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(colorValue),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String selected;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _IconPicker({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = HabitAppearance.icons.keys.toList();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final key = keys[index];
          final isSelected = key == selected;
          return GestureDetector(
            onTap: () => onChanged(key),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Icon(
                HabitAppearance.icons[key],
                size: 20,
                color: isSelected
                    ? accentColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final TimeOfDay? reminderTime;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ReminderRow({
    required this.reminderTime,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReminder = reminderTime != null;

    return Row(
      children: [
        Icon(
          hasReminder
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasReminder
                ? 'Recordatorio a las ${reminderTime!.format(context)}'
                : 'Sin recordatorio propio',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (hasReminder)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: 'Quitar recordatorio',
          ),
        TextButton(
          onPressed: onPick,
          child: Text(hasReminder ? 'Cambiar' : 'Añadir'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final bool hasKeyboard;
  final bool isEditing;

  const _Header({required this.hasKeyboard, this.isEditing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _HeaderIcon(hasKeyboard: hasKeyboard, theme: theme),
        const SizedBox(width: 12),
        _HeaderText(
          hasKeyboard: hasKeyboard,
          theme: theme,
          isEditing: isEditing,
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final bool hasKeyboard;
  final ThemeData theme;

  const _HeaderIcon({required this.hasKeyboard, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: hasKeyboard ? 36 : 40,
      height: hasKeyboard ? 36 : 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.add_circle_outline,
        color: theme.colorScheme.primary,
        size: hasKeyboard ? 20 : 22,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final bool hasKeyboard;
  final ThemeData theme;
  final bool isEditing;

  const _HeaderText({
    required this.hasKeyboard,
    required this.theme,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Editar hábito' : 'Nuevo hábito',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: hasKeyboard ? 17 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final bool hasKeyboard;
  final bool showEvaluation;
  final bool isEvaluating;
  final String evaluationText;
  final VoidCallback onClose;

  const _InfoSection({
    required this.hasKeyboard,
    required this.showEvaluation,
    required this.isEvaluating,
    required this.evaluationText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher da una transición suave y determinista entre tips y
    // resultado, sin depender de un AnimationController externo (que a veces
    // dejaba la tarjeta en opacidad 0).
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: showEvaluation
          ? _EvaluationCard(
              key: const ValueKey('eval'),
              hasKeyboard: hasKeyboard,
              isEvaluating: isEvaluating,
              evaluationText: evaluationText,
              onClose: onClose,
            )
          : _TipsCard(key: const ValueKey('tips'), hasKeyboard: hasKeyboard),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final bool hasKeyboard;

  const _TipsCard({super.key, required this.hasKeyboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(hasKeyboard ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(hasKeyboard ? 12 : 10),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTipsHeader(),
          SizedBox(height: hasKeyboard ? 8 : 6),
          ..._TipsData.tips.map((tip) => _buildTipRow(tip)),
        ],
      ),
    );
  }

  Widget _buildTipsHeader() {
    return Row(
      children: [
        Icon(
          Icons.tips_and_updates,
          color: Colors.blue[600],
          size: hasKeyboard ? 18 : 16,
        ),
        const SizedBox(width: 8),
        Text(
          'Consejos para el éxito',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blue[700],
            fontSize: hasKeyboard ? 14 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow(_TipModel tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: hasKeyboard ? 4 : 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tip.emoji,
            style: TextStyle(fontSize: hasKeyboard ? 12 : 11),
          ),
          SizedBox(width: hasKeyboard ? 8 : 6),
          Expanded(
            child: Text(
              tip.text,
              style: TextStyle(
                fontSize: hasKeyboard ? 12 : 11,
                color: Colors.blue[700],
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final bool hasKeyboard;
  final bool isEvaluating;
  final String evaluationText;
  final VoidCallback onClose;

  const _EvaluationCard({
    super.key,
    required this.hasKeyboard,
    required this.isEvaluating,
    required this.evaluationText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hasKeyboard ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(hasKeyboard ? 12 : 10),
        border: Border.all(color: Colors.green[100]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEvaluationHeader(),
          if (!isEvaluating) ...[
            SizedBox(height: hasKeyboard ? 8 : 6),
            _buildEvaluationContent(evaluationText, hasKeyboard),
          ],
        ],
      ),
    );
  }

  Widget _buildEvaluationHeader() {
    return Row(
      children: [
        if (isEvaluating)
          SizedBox(
            width: hasKeyboard ? 18 : 16,
            height: hasKeyboard ? 18 : 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          )
        else
          Icon(
            Icons.auto_awesome,
            color: Colors.green[600],
            size: hasKeyboard ? 18 : 16,
          ),
        const SizedBox(width: 8),
        Text(
          isEvaluating ? 'Analizando...' : 'Evaluación IA',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
            fontSize: hasKeyboard ? 14 : 13,
          ),
        ),
        const Spacer(),
        if (!isEvaluating)
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: hasKeyboard ? 16 : 14,
              color: Colors.green[600],
            ),
          ),
      ],
    );
  }

  Widget _buildEvaluationContent(String text, bool hasKeyboard) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Text(
            line.trim(),
            style: TextStyle(
              fontSize: hasKeyboard ? 12 : 11,
              color: Colors.green[700],
              height: 1.2,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HabitTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasKeyboard;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onClear;

  const _HabitTextField({
    required this.controller,
    required this.focusNode,
    required this.hasKeyboard,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final theme = Theme.of(context);

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Ej: Beber un vaso de agua',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            hintStyle: TextStyle(
              color: Colors.grey[500]?.withOpacity(0.7), 
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onClear();
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: hasKeyboard ? 14 : 12,
            ),
          ),
          validator: _HabitValidator.validate,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmitted(),
          onChanged: onChanged,
          maxLength: 60,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        );
      },
    );
  }
}

class _EvaluateButton extends StatelessWidget {
  final bool hasKeyboard;
  final bool canEvaluate;
  final VoidCallback onPressed;

  const _EvaluateButton({
    required this.hasKeyboard,
    required this.canEvaluate,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hasKeyboard ? 40 : 36,
      child: OutlinedButton.icon(
        onPressed: canEvaluate ? onPressed : null,
        icon: Icon(
          Icons.psychology,
          size: 16,
          color: canEvaluate ? Colors.green[600] : Colors.grey[400],
        ),
        label: Text(
          'Evaluar con IA',
          style: TextStyle(
            color: canEvaluate ? Colors.green[600] : Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(
            color: canEvaluate
                ? Colors.green[600]!.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool hasKeyboard;
  final bool canAddHabit;
  final bool isEditing;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _ActionButtons({
    required this.hasKeyboard,
    required this.canAddHabit,
    this.isEditing = false,
    required this.onCancel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: hasKeyboard ? 48 : 44,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: hasKeyboard ? 48 : 44,
            child: FilledButton(
              onPressed: canAddHabit ? onAdd : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: canAddHabit
                    ? theme.colorScheme.primary
                    : Colors.grey[300],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEditing ? Icons.check : Icons.add,
                    size: 18,
                    color: canAddHabit ? Colors.white : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Guardar' : 'Crear hábito',
                    style: TextStyle(
                      color: canAddHabit ? Colors.white : Colors.grey[500],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdaptiveBottomSheet extends StatelessWidget {
  final Widget child;

  const _AdaptiveBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final height = keyboardHeight > 0
        ? screenHeight * 0.92
        : screenHeight * 0.78;

    return SizedBox(
      height: height,
      child: child,
    );
  }
}

class _TipModel {
  final String emoji;
  final String text;

  const _TipModel({required this.emoji, required this.text});
}

class _TipsData {
  static const List<_TipModel> tips = [
    _TipModel(emoji: '📅', text: 'Define una acción clara que puedas marcar como "hecha" hoy. No más de una frase.'),
    _TipModel(emoji: '🎯', text: 'Lo importante es la constancia diaria. No te exijas perfección.'),
  ];
}

class _HabitValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Describe tu tarea diaria'; // Mensaje de validación ajustado
    }
    if (value.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }
}