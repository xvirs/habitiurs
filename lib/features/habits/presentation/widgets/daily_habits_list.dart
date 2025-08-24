import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/habit.dart';
import 'habit_tile.dart';
import 'delete_confirmation_dialog.dart';
import '../../../../shared/enums/habit_status.dart';

class DailyHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final void Function(int, HabitStatus) onToggle;
  final void Function(int, String) onDelete;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Hábitos de hoy', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
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

class _SwipeableHabitTile extends StatelessWidget {
  final Habit habit;
  final int index;
  final HabitStatus status;
  final void Function(int, HabitStatus) onToggle;
  final void Function(int, String) onDelete;

  const _SwipeableHabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.status,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${habit.id}'),
      direction: DismissDirection.startToEnd,
      background: const _SwipeDeleteBackground(),
      confirmDismiss: (direction) async {
        onDelete(habit.id!, habit.name);
        return false; // La page decide si elimina realmente el item
      },
      child: HabitTile(
        habit: habit,
        index: index,
        status: status,
        onToggle: onToggle,
        onDelete: (_, __) {}, // No longer usado
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
        color: Colors.red[400],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 24),
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