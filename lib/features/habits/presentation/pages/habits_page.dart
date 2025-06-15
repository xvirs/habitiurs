// lib/features/habits/presentation/pages/habits_page.dart - UI MEJORADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/habits/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../bloc/habit_bloc.dart';
import '../bloc/habit_event.dart';
import '../bloc/habit_state.dart';
import '../widgets/weekly_grid.dart';
import '../widgets/daily_habits_list.dart';
import '../widgets/add_habit_dialog.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InjectionContainer().habitBloc..add(LoadHabits()),
      child: const _HabitsPageView(),
    );
  }
}

class _HabitsPageView extends StatelessWidget {
  const _HabitsPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Hábitos Diarios'),
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddHabitDialog(context),
          tooltip: 'Agregar hábito',
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, HabitState state) {
    return switch (state) {
      HabitLoading() => const Center(child: CircularProgressIndicator()),
      HabitError() => _buildErrorView(context, state),
      HabitLoaded() => _buildLoadedView(context, state),
      _ => const Center(child: Text('Estado inicial')),
    };
  }

  Widget _buildErrorView(BuildContext context, HabitError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<HabitBloc>().add(LoadHabits()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, HabitLoaded state) {
    final today = DateTime.now();
    final todayEntries = state.weekEntries
        .where((entry) => AppDateUtils.isSameDay(entry.date, today)) 
        .toList();

    return Column(
      children: [
        // Cuadrícula semanal - Parte superior
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: WeeklyGrid(
              habits: state.habits,
              weekEntries: state.weekEntries,
              weekStart: state.currentWeekStart,
              onToggle: (habitId, date, currentStatus) => _handleToggle(
                context,
                habitId,
                date,
                currentStatus,
              ),
              onDelete: (habitId) => _showDeleteConfirmation(context, habitId),
            ),
          ),
        ),
        // Lista de hábitos diarios - Parte inferior
        Expanded(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DailyHabitsList(
              habits: state.habits,
              todayEntries: todayEntries,
              onToggle: (habitId, currentStatus) => _handleToggle(
                context,
                habitId,
                today,
                currentStatus,
              ),
              onDelete: (habitId) => _showDeleteConfirmation(context, habitId),
            ),
          ),
        ),
      ],
    );
  }

  void _handleToggle(BuildContext context, int habitId, DateTime date, HabitStatus currentStatus) {
    context.read<HabitBloc>().add(
      ToggleHabitEntryEvent(
        habitId: habitId,
        date: date,
        currentStatus: currentStatus,
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddHabitDialog(
        onAdd: (name) => context.read<HabitBloc>().add(CreateHabitEvent(name)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int habitId) {
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        onConfirm: () => context.read<HabitBloc>().add(DeleteHabitEvent(habitId)),
      ),
    );
  }
}