import 'package:flutter/material.dart';
import 'package:habitiurs/core/service/vibration_service.dart';
import '../../domain/entities/habit.dart';
import 'habit_tile.dart';
import '../../../../shared/enums/habit_status.dart';

class DailyHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final void Function(int, HabitStatus) onToggle;
  final void Function(int, String) onDelete;
  final void Function(Habit)? onEdit;
  final VoidCallback onAdd;
  final bool isLoading;

  const DailyHabitsList({
    super.key,
    required this.habits,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
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
      onEdit: onEdit,
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onAdd;
  const _HeaderSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Hábitos de hoy', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              VibrationService.medium(); // Vibración para crear hábito
              onAdd();
            },
            tooltip: 'Agregar hábito',
          ),
        ],
      ),
    );
  }
}

class _HabitsListView extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final void Function(int, HabitStatus) onToggle;
  final void Function(int, String) onDelete;
  final void Function(Habit)? onEdit;

  const _HabitsListView({
    required this.habits,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
            onEdit: onEdit,
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
  final void Function(int, HabitStatus) onToggle;
  final void Function(int, String) onDelete;
  final void Function(Habit)? onEdit;

  const _SwipeableHabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.status,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
  });

  @override
  State<_SwipeableHabitTile> createState() => _SwipeableHabitTileState();
}

class _SwipeableHabitTileState extends State<_SwipeableHabitTile> {
  bool _hasVibrated = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${widget.habit.id}'),
      direction: DismissDirection.startToEnd,
      background: const _SwipeDeleteBackground(),
      
      // Configuración para hacer el swipe menos sensible
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.6, // Requiere 60% del ancho para activar
      },
      movementDuration: const Duration(milliseconds: 300),
      resizeDuration: const Duration(milliseconds: 200),
      
      // Vibración progresiva basada en el progreso del swipe
      onUpdate: (details) {
        // Vibrar cuando se alcanza el 50% del threshold (30% del ancho total)
        if (details.progress > 0.3 && !_hasVibrated) {
          _hasVibrated = true;
          VibrationService.warning(); // Vibración de advertencia
        } else if (details.progress <= 0.3) {
          _hasVibrated = false;
        }
      },
      
      confirmDismiss: (direction) async {
        // Vibración final al confirmar el swipe
        await VibrationService.warning();
        widget.onDelete(widget.habit.id!, widget.habit.name);
        return false; // La page decide si elimina realmente el item
      },
      
      child: HabitTile(
        habit: widget.habit,
        index: widget.index,
        status: widget.status,
        onToggle: (habitId, currentStatus) {
          // Vibración diferente según el estado
          if (currentStatus == HabitStatus.pending) {
            VibrationService.success(); // Vibración suave al completar
          } else {
            VibrationService.selection(); // Vibración ligera al desmarcar
          }
          widget.onToggle(habitId, currentStatus);
        },
        onDelete: (_, __) {}, // No longer usado
        onEdit: widget.onEdit,
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[300]!,
            Colors.red[500]!,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_outline, 
              color: Colors.white, 
              size: 24
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eliminar hábito',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sincronizando tus hábitos',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando todo para ti...',
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