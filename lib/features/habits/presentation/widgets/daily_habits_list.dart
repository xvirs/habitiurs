// lib/features/habits/presentation/widgets/daily_habits_list.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/habit.dart';
import 'habit_tile.dart';
import '../../../../shared/enums/habit_status.dart';

class DailyHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final OnHabitToggleCallback onToggle;
  final OnHabitDeleteCallback onDelete;
  final VoidCallback onAdd;
  final bool isLoading;

  const DailyHabitsList({
    super.key,
    required this.habits,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(onAdd: onAdd),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) return const _LoadingState();
    if (habits.isEmpty) return const _EmptyState();
    
    return _HabitsListView(
      habits: habits,
      todayEntriesMap: todayEntriesMap,
      onToggle: onToggle,
      onDelete: onDelete,
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onAdd;

  const _HeaderSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _VerticalAccent(color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Icon(
            Icons.today,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hábitos de hoy',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _AddButton(onPressed: onAdd),
        ],
      ),
    );
  }
}

class _VerticalAccent extends StatelessWidget {
  final Color color;

  const _VerticalAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _HabitsListView extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final OnHabitToggleCallback onToggle;
  final OnHabitDeleteCallback onDelete;

  const _HabitsListView({
    required this.habits,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: habits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final habit = habits[index];
          final status = todayEntriesMap[habit.id!] ?? HabitStatus.pending;

          return _SwipeableHabitTile(
            key: ValueKey(habit.id),
            habit: habit,
            index: index,
            status: status,
            onToggle: onToggle,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}

class _SwipeableHabitTile extends StatefulWidget {
  final Habit habit;
  final int index;
  final HabitStatus status;
  final OnHabitToggleCallback onToggle;
  final OnHabitDeleteCallback onDelete;

  const _SwipeableHabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.status,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_SwipeableHabitTile> createState() => _SwipeableHabitTileState();
}

class _SwipeableHabitTileState extends State<_SwipeableHabitTile>
    with TickerProviderStateMixin {
  static const double _deleteThreshold = 0.4;
  static const Duration _animationDuration = Duration(milliseconds: 200);
  
  bool _isBeingDeleted = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${widget.habit.id}'),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: _deleteThreshold},
      onUpdate: _handleSwipeUpdate,
      confirmDismiss: _handleSwipeComplete,
      background: const _SwipeDeleteBackground(),
      child: AnimatedOpacity(
        opacity: _isBeingDeleted ? 0.5 : 1.0,
        duration: _animationDuration,
        child: HabitTile(
          habit: widget.habit,
          index: widget.index,
          status: widget.status,
          onToggle: widget.onToggle,
          onDelete: (_) {}, // No longer used
        ),
      ),
    );
  }

  void _handleSwipeUpdate(DismissUpdateDetails details) {
    if (details.progress > _deleteThreshold && 
        details.progress < _deleteThreshold + 0.1) {
      HapticFeedback.lightImpact();
    }
  }

  Future<bool> _handleSwipeComplete(DismissDirection direction) async {
    _triggerDeleteConfirmation();
    return false; // Prevent auto-dismiss
  }

  void _triggerDeleteConfirmation() {
    if (_isBeingDeleted) return;

    setState(() => _isBeingDeleted = true);
    HapticFeedback.mediumImpact();
    _showDeleteDialog();
  }

  void _showDeleteDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _HabitDeleteDialog(
        habitName: widget.habit.name,
        onConfirm: _confirmDelete,
        onCancel: _cancelDelete,
      ),
    ).then((_) => _resetTileIfNeeded());
  }

  void _confirmDelete() {
    Navigator.of(context).pop();
    widget.onDelete(widget.habit.id!);
  }

  void _cancelDelete() {
    Navigator.of(context).pop();
    _resetTile();
  }

  void _resetTileIfNeeded() {
    if (mounted && _isBeingDeleted) {
      _resetTile();
    }
  }

  void _resetTile() {
    if (mounted) {
      setState(() => _isBeingDeleted = false);
    }
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          _PulsingDeleteIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Eliminar hábito',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDeleteIcon extends StatefulWidget {
  const _PulsingDeleteIcon();

  @override
  State<_PulsingDeleteIcon> createState() => _PulsingDeleteIconState();
}

class _PulsingDeleteIconState extends State<_PulsingDeleteIcon>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _HabitDeleteDialog extends StatelessWidget {
  final String habitName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _HabitDeleteDialog({
    required this.habitName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _DialogTitle(theme: theme),
      content: _DialogContent(habitName: habitName, theme: theme),
      actions: [
        _DialogActions(
          onCancel: onCancel,
          onConfirm: onConfirm,
          theme: theme,
        ),
      ],
    );
  }
}

class _DialogTitle extends StatelessWidget {
  final ThemeData theme;

  const _DialogTitle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Eliminar hábito',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogContent extends StatelessWidget {
  final String habitName;
  final ThemeData theme;

  const _DialogContent({
    required this.habitName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HabitNameContainer(habitName: habitName, theme: theme),
        const SizedBox(height: 8),
        Text(
          'Esta acción no se puede deshacer.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _HabitNameContainer extends StatelessWidget {
  final String habitName;
  final ThemeData theme;

  const _HabitNameContainer({
    required this.habitName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$habitName"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final ThemeData theme;

  const _DialogActions({
    required this.onCancel,
    required this.onConfirm,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_task,
              size: 48,
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes hábitos',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar tu primer hábito',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}