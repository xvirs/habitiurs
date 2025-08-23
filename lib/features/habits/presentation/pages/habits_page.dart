// lib/features/habits/presentation/pages/habits_page.dart
import 'package:habitiurs/core/utils/widget_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/habits/domain/entities/habit_entry.dart';
import 'package:habitiurs/features/habits/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../bloc/habit_bloc.dart';
import '../bloc/habit_event.dart';
import '../bloc/habit_state.dart';
import '../widgets/weekly_grid.dart';
import '../widgets/daily_habits_list.dart';
import '../widgets/add_habit_bottom_sheet.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => HabitsPageState();
}

class HabitsPageState extends State<HabitsPage>
    with AutomaticKeepAliveClientMixin {
  late final DateTime _today;
  bool _hasTriedAutoReload = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HabitBloc>().add(LoadHabits());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<HabitBloc, HabitState>(
      listener: _handleStateChanges,
      builder: (context, state) => _buildBody(context, state),
    );
  }

  void _handleStateChanges(BuildContext context, HabitState state) {
    if (state is HabitError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () => context.read<HabitBloc>().add(LoadHabits()),
          ),
        ),
      );
    }

    // Auto-reload cuando la lista está vacía (solo una vez)
    if (state is HabitLoaded && 
        state.habits.isEmpty && 
        !state.isRefreshing && 
        !_hasTriedAutoReload) {
      _hasTriedAutoReload = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HabitBloc>().add(PullToRefresh());
        }
      });
    }
  }

  Widget _buildBody(BuildContext context, HabitState state) {
    return switch (state) {
      HabitLoading() => const _LoadingView(),
      HabitError() => _ErrorView(
          message: state.message,
          onRetry: () => context.read<HabitBloc>().add(LoadHabits()),
        ),
      HabitLoaded() => _LoadedView(
          state: state,
          todayEntriesMap: _getTodayEntriesMap(state.weekEntries),
          onToggle: _handleToggle,
          onDelete: _handleDelete,
          onAdd: _handleAdd,
        ),
      _ => const _LoadingView(),
    };
  }

  Map<int, HabitStatus> _getTodayEntriesMap(List<HabitEntry> weekEntries) {
    return {
      for (final entry in weekEntries)
        if (AppDateUtils.isSameDay(entry.date, _today))
          entry.habitId: entry.status,
    };
  }

  void _handleToggle(int habitId, HabitStatus currentStatus) {
    context.read<HabitBloc>().add(
      ToggleHabitEntryEvent(
        habitId: habitId,
        date: _today,
        currentStatus: currentStatus,
      ),
    );
    WidgetUpdater.refreshWeeklyHabitsWidget();
  }

  void _handleDelete(int habitId) {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmationDialog(
        onConfirm: () {
          context.read<HabitBloc>().add(DeleteHabitEvent(habitId));
          WidgetUpdater.refreshWeeklyHabitsWidget();
        },
      ),
    );
  }

  void _handleAdd() {
    AddHabitBottomSheet.show(
      context,
      onAdd: (habitName) {
        context.read<HabitBloc>().add(CreateHabitEvent(habitName));
        WidgetUpdater.refreshWeeklyHabitsWidget();
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando hábitos...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: _ErrorContent(
            message: message,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorContent({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final HabitLoaded state;
  final Map<int, HabitStatus> todayEntriesMap;
  final void Function(int, HabitStatus) onToggle;
  final void Function(int) onDelete;
  final VoidCallback onAdd;

  const _LoadedView({
    required this.state,
    required this.todayEntriesMap,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: WeeklyGrid(
                habits: state.habits,
                weekEntries: state.weekEntries,
                weekStart: state.currentWeekStart,
                isLoading: state.isRefreshing,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: DailyHabitsList(
            habits: state.habits,
            todayEntriesMap: todayEntriesMap,
            onToggle: onToggle,
            onDelete: onDelete,
            onAdd: onAdd,
            isLoading: state.isRefreshing,
          ),
        ),
      ],
    );
  }
}