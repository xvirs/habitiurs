// lib/features/habits/presentation/widgets/add_habit_bottom_sheet.dart - OPTIMIZADO
import 'package:flutter/material.dart';

class AddHabitBottomSheet extends StatefulWidget {
  final Function(String) onAdd;

  const AddHabitBottomSheet({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();

  // Método estático para mostrar el BottomSheet
  static void show(BuildContext context, {required Function(String) onAdd}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => _AdaptiveBottomSheet(
        child: AddHabitBottomSheet(onAdd: onAdd),
      ),
    );
  }
}

class _AddHabitBottomSheetState extends State<AddHabitBottomSheet> 
    with SingleTickerProviderStateMixin {
  
  // Controllers y focus
  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;
  late final FocusNode _focusNode;
  
  // Animación
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  // Estado
  bool _isEvaluating = false;
  bool _showEvaluation = false;
  String _evaluationText = '';

  // Constantes
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const Duration _evaluationDelay = Duration(seconds: 2);
  static const int _minHabitLength = 3;
  static const int _maxHabitLength = 60;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimation();
  }

  void _initializeControllers() {
    _controller = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _focusNode = FocusNode();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = keyboardHeight > 0;
    
    return _BottomSheetContainer(
      child: _BottomSheetContent(
        hasKeyboard: hasKeyboard,
        formKey: _formKey,
        controller: _controller,
        focusNode: _focusNode,
        isEvaluating: _isEvaluating,
        showEvaluation: _showEvaluation,
        evaluationText: _evaluationText,
        fadeAnimation: _fadeAnimation,
        onEvaluate: _evaluateHabit,
        onHideEvaluation: _hideEvaluation,
        onAddHabit: _addHabit,
        onTextChanged: _onTextChanged,
        canAddHabit: _canAddHabit,
      ),
    );
  }

  // Métodos de negocio
  bool get _canAddHabit => _controller.text.trim().length >= _minHabitLength;

  void _onTextChanged(String value) {
    setState(() {
      if (_showEvaluation && value.trim().length < _minHabitLength) {
        _hideEvaluation();
      }
    });
  }

  Future<void> _evaluateHabit() async {
    if (!_canAddHabit) return;
    
    setState(() {
      _isEvaluating = true;
      _showEvaluation = true;
    });
    
    _animationController.forward();

    // Simular evaluación de IA
    await Future.delayed(_evaluationDelay);
    
    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _evaluationText = _MockEvaluationGenerator.generate(_controller.text.trim());
      });
    }
  }

  void _hideEvaluation() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showEvaluation = false;
          _evaluationText = '';
        });
      }
    });
  }

  void _addHabit() {
    if (_formKey.currentState?.validate() ?? false) {
      _focusNode.unfocus();
      widget.onAdd(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }
}

// Widget para detectar teclado de forma reactiva (ELIMINADO - no se usa)

// Contenedor principal del bottom sheet
class _BottomSheetContainer extends StatelessWidget {
  final Widget child;

  const _BottomSheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

// Contenido principal
class _BottomSheetContent extends StatelessWidget {
  final bool hasKeyboard;
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEvaluating;
  final bool showEvaluation;
  final String evaluationText;
  final Animation<double> fadeAnimation;
  final VoidCallback onEvaluate;
  final VoidCallback onHideEvaluation;
  final VoidCallback onAddHabit;
  final ValueChanged<String> onTextChanged;
  final bool canAddHabit;

  const _BottomSheetContent({
    required this.hasKeyboard,
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.isEvaluating,
    required this.showEvaluation,
    required this.evaluationText,
    required this.fadeAnimation,
    required this.onEvaluate,
    required this.onHideEvaluation,
    required this.onAddHabit,
    required this.onTextChanged,
    required this.canAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        hasKeyboard ? 20 : 18,
        20,
        hasKeyboard ? 20 : 12,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(hasKeyboard: hasKeyboard),
            SizedBox(height: hasKeyboard ? 16 : 14),
            _InfoSection(
              hasKeyboard: hasKeyboard,
              showEvaluation: showEvaluation,
              isEvaluating: isEvaluating,
              evaluationText: evaluationText,
              fadeAnimation: fadeAnimation,
              onHideEvaluation: onHideEvaluation,
            ),
            SizedBox(height: hasKeyboard ? 16 : 12),
            _HabitTextField(
              controller: controller,
              focusNode: focusNode,
              hasKeyboard: hasKeyboard,
              onChanged: onTextChanged,
              onSubmitted: canAddHabit ? onAddHabit : null,
              onClear: onHideEvaluation,
            ),
            SizedBox(height: hasKeyboard ? 14 : 10),
            _EvaluateButton(
              hasKeyboard: hasKeyboard,
              canEvaluate: canAddHabit && !showEvaluation,
              onPressed: onEvaluate,
            ),
            SizedBox(height: hasKeyboard ? 16 : 12),
            _ActionButtons(
              hasKeyboard: hasKeyboard,
              canAddHabit: canAddHabit,
              onCancel: () => Navigator.of(context).pop(),
              onAdd: onAddHabit,
            ),
          ],
        ),
      ),
    );
  }
}

// Header component
class _Header extends StatelessWidget {
  final bool hasKeyboard;

  const _Header({required this.hasKeyboard});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        _HeaderIcon(hasKeyboard: hasKeyboard, theme: theme),
        const SizedBox(width: 12),
        _HeaderText(hasKeyboard: hasKeyboard, theme: theme),
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

  const _HeaderText({required this.hasKeyboard, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nuevo Hábito',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: hasKeyboard ? 17 : 18,
            ),
          ),
          Text(
            hasKeyboard 
                ? 'Describe tu hábito ideal'
                : 'Crea un hábito sostenible',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Sección de información
class _InfoSection extends StatelessWidget {
  final bool hasKeyboard;
  final bool showEvaluation;
  final bool isEvaluating;
  final String evaluationText;
  final Animation<double> fadeAnimation;
  final VoidCallback onHideEvaluation;

  const _InfoSection({
    required this.hasKeyboard,
    required this.showEvaluation,
    required this.isEvaluating,
    required this.evaluationText,
    required this.fadeAnimation,
    required this.onHideEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    return showEvaluation
        ? _EvaluationCard(
            hasKeyboard: hasKeyboard,
            isEvaluating: isEvaluating,
            evaluationText: evaluationText,
            fadeAnimation: fadeAnimation,
            onClose: onHideEvaluation,
          )
        : _TipsCard(hasKeyboard: hasKeyboard);
  }
}

// Card de consejos
class _TipsCard extends StatelessWidget {
  final bool hasKeyboard;

  const _TipsCard({required this.hasKeyboard});

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

// Card de evaluación
class _EvaluationCard extends StatelessWidget {
  final bool hasKeyboard;
  final bool isEvaluating;
  final String evaluationText;
  final Animation<double> fadeAnimation;
  final VoidCallback onClose;

  const _EvaluationCard({
    required this.hasKeyboard,
    required this.isEvaluating,
    required this.evaluationText,
    required this.fadeAnimation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
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
              _buildEvaluationContent(),
            ],
          ],
        ),
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

  Widget _buildEvaluationContent() {
    return Text(
      evaluationText,
      style: TextStyle(
        fontSize: hasKeyboard ? 12 : 11,
        color: Colors.green[700],
        height: 1.2,
      ),
    );
  }
}

// Campo de texto
class _HabitTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasKeyboard;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
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
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Describe tu hábito',
            hintText: 'Ej: Leer 10 páginas cada mañana',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.track_changes, size: 20),
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
          onFieldSubmitted: (_) => onSubmitted?.call(),
          onChanged: onChanged,
          maxLength: 60,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        );
      },
    );
  }
}

// Botón de evaluación
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

// Botones de acción
class _ActionButtons extends StatelessWidget {
  final bool hasKeyboard;
  final bool canAddHabit;
  final VoidCallback onCancel;
  final VoidCallback onAdd;

  const _ActionButtons({
    required this.hasKeyboard,
    required this.canAddHabit,
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
                    Icons.add,
                    size: 18,
                    color: canAddHabit ? Colors.white : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Crear Hábito',
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

// Widget wrapper que maneja la altura adaptativa
class _AdaptiveBottomSheet extends StatelessWidget {
  final Widget child;

  const _AdaptiveBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final height = keyboardHeight > 0 
        ? screenHeight * 0.89
        : screenHeight * 0.47;

    return SizedBox(
      height: height,
      child: child,
    );
  }
}

// Clases de datos y utilidades
class _TipModel {
  final String emoji;
  final String text;

  const _TipModel({required this.emoji, required this.text});
}

class _TipsData {
  static const List<_TipModel> tips = [
    _TipModel(emoji: '📝', text: 'Sé específico: "Leer 10 páginas"'),
    _TipModel(emoji: '🎯', text: 'Comienza pequeño: 5 min diarios'),
    _TipModel(emoji: '🔗', text: 'Vincúlalo con rutina existente'),
  ];
}

class _HabitValidator {
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Describe tu hábito';
    }
    if (value.trim().length < 3) {
      return 'Mínimo 3 caracteres';
    }
    return null;
  }
}

class _MockEvaluationGenerator {
  static String generate(String habit) {
    return '✅ Bien estructurado y específico.\n\n💡 Sugerencia: Añade horario específico.\n\n🎯 Éxito probable: Alto';
  }
}