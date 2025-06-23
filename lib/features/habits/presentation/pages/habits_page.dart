// lib/features/habits/presentation/pages/habits_page.dart
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
import '../../../../core/di/injection_container.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => HabitsPageState();
}

class HabitsPageState extends State<HabitsPage>
    with AutomaticKeepAliveClientMixin {
  late final HabitBloc _habitBloc;
  late final DateTime _today;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _habitBloc = InjectionContainer().habitBloc..add(LoadHabits());
  }

  @override
  void dispose() {
    _habitBloc.close();
    super.dispose();
  }

  void refreshData() {
    _habitBloc.add(PullToRefresh());
  }

  Future<void> _onRefresh() async {
    _habitBloc.add(PullToRefresh());
    await _waitForRefreshComplete();
  }

  Future<void> _waitForRefreshComplete() async {
    await for (final state in _habitBloc.stream) {
      if (state is HabitLoaded && !state.isRefreshing) break;
      if (state is HabitError) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _habitBloc,
      child: BlocConsumer<HabitBloc, HabitState>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildBody(context, state),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, HabitState state) {
    if (state is HabitError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () => _habitBloc.add(LoadHabits()),
          ),
        ),
      );
    }
  }

  Widget _buildBody(BuildContext context, HabitState state) {
    return switch (state) {
      HabitLoading() => _buildLoadingView(),
      HabitError() => _buildErrorView(context, state),
      HabitLoaded() => _buildLoadedView(context, state),
      _ => _buildInitialView(),
    };
  }

  Widget _buildLoadingView() {
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

  Widget _buildInitialView() {
    return const Center(child: Text('Inicializando...'));
  }

  Widget _buildErrorView(BuildContext context, HabitError state) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: _ErrorStateWidget(
              message: state.message,
              onRetry: () => _habitBloc.add(LoadHabits()),
              onRefresh: _onRefresh,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, HabitLoaded state) {
    final todayEntriesMap = _getTodayEntriesMap(state.weekEntries);

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            displacement: 40,
            color: Theme.of(context).colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: WeeklyGrid(
                  habits: state.habits,
                  weekEntries: state.weekEntries,
                  weekStart: state.currentWeekStart,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: DailyHabitsList(
            habits: state.habits,
            todayEntriesMap: todayEntriesMap,
            onToggle: _handleToggle,
            onDelete: _handleDelete,
            onAdd: _handleAdd,
          ),
        ),
      ],
    );
  }

  /// NUEVO: Mapea las entradas de hoy a habitId -> status
  Map<int, HabitStatus> _getTodayEntriesMap(List<HabitEntry> weekEntries) {
    return {
      for (final entry in weekEntries)
        if (AppDateUtils.isSameDay(entry.date, _today)) entry.habitId: entry.status
    };
  }

  void _handleToggle(int habitId, HabitStatus currentStatus) {
    _habitBloc.add(
      ToggleHabitEntryEvent(
        habitId: habitId,
        date: _today,
        currentStatus: currentStatus,
      ),
    );
  }

  void _handleDelete(int habitId) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onConfirm: () => _habitBloc.add(DeleteHabitEvent(habitId)),
      ),
    );
  }

  void _handleAdd() {
    AddHabitBottomSheet.show(
      context,
      onAdd: (habitName) => _habitBloc.add(CreateHabitEvent(habitName)),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;

  const _ErrorStateWidget({
    required this.message,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Sincronizar con la nube'),
          ),
        ],
      ),
    );
  }
}
