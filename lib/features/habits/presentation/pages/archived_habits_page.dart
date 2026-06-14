// lib/features/habits/presentation/pages/archived_habits_page.dart
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_appearance.dart';
import '../bloc/habit_event.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Pantalla de hábitos archivados: permite restaurarlos o eliminarlos.
class ArchivedHabitsPage extends StatefulWidget {
  const ArchivedHabitsPage({super.key});

  @override
  State<ArchivedHabitsPage> createState() => _ArchivedHabitsPageState();
}

class _ArchivedHabitsPageState extends State<ArchivedHabitsPage> {
  late Future<List<Habit>> _archivedHabits;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _archivedHabits = InjectionContainer().habitRepository.getArchivedHabits();
  }

  void _restore(Habit habit) {
    InjectionContainer().habitBloc.add(SetHabitArchivedEvent(habit, false));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hábito "${habit.name}" restaurado')),
    );
    setState(_reload);
  }

  void _delete(Habit habit) {
    DeleteConfirmationDialog.show(
      context,
      habitName: habit.name,
      onConfirm: () {
        InjectionContainer().habitBloc.add(DeleteHabitEvent(habit.id!));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hábito "${habit.name}" eliminado')),
        );
        setState(_reload);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hábitos archivados',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<Habit>>(
        future: _archivedHabits,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = snapshot.data ?? [];
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes hábitos archivados',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(habit.colorValue),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        HabitAppearance.iconFor(habit.iconKey),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        habit.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined),
                      tooltip: 'Restaurar',
                      onPressed: () => _restore(habit),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Eliminar',
                      onPressed: () => _delete(habit),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
