import 'package:flutter/material.dart';
import '../../domain/entities/habit.dart';
import 'habit_tile.dart';
import '../../../../shared/enums/habit_status.dart';

class DailyHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final Function(int habitId, HabitStatus currentStatus) onToggle;
  final Function(int habitId) onDelete;
  final VoidCallback onAdd;

  const DailyHabitsList({
    super.key,
    required this.habits,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(onAdd: onAdd),
          Expanded(
            child: habits.isEmpty
                ? const _EmptyStateWidget() // Muestra un widget de estado vacío si no hay hábitos
                : _HabitsListView( // Muestra la lista si hay hábitos
                    habits: habits,
                    todayEntriesMap: todayEntriesMap,
                    onToggle: onToggle,
                    onDelete: onDelete,
                  ),
          ),
          // Eliminado el widget: AIHabitSuggestions
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onAdd;

  const _HeaderSection({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _VerticalAccent(color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Icon(
            Icons.today,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hábitos de hoy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _HabitsListView extends StatelessWidget {
  final List<Habit> habits;
  final Map<int, HabitStatus> todayEntriesMap;
  final Function(int habitId, HabitStatus currentStatus) onToggle;
  final Function(int habitId) onDelete;

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
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final habit = habits[index];
          // Se accede a habit.id! solo si habit no es nulo, lo cual está garantizado por el itemCount
          final status = todayEntriesMap[habit.id!] ?? HabitStatus.pending; 

          return HabitTile(
            // AÑADIDO: Se añade una Key explícita usando ValueKey con el ID del hábito.
            // Esto es crucial para ayudar a Flutter a reconciliar eficientemente los widgets
            // cuando los elementos se eliminan o se reordenan en una lista dinámica.
            key: ValueKey(habit.id), 
            habit: habit,
            index: index,
            status: status,
            onToggle: () => onToggle(habit.id!, status),
            onDelete: () => onDelete(habit.id!),
          );
        },
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_task,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes hábitos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar tu primer hábito',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

