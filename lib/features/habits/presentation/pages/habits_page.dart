// lib/features/habits/presentation/pages/habits_page.dart
import 'package:habitiurs/core/service/vibration_service.dart';
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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late DateTime _lastLoadDate;
  bool _hasTriedAutoReload = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _lastLoadDate = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HabitBloc>().add(LoadHabits());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cuando la app vuelve del background o se reactiva
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      // Verificar si cambió el día desde la última carga
      if (!AppDateUtils.isSameDay(now, _lastLoadDate)) {
        print('🔄 [HabitsPage] Día cambió de ${AppDateUtils.formatToYYYYMMDD(_lastLoadDate)} a ${AppDateUtils.formatToYYYYMMDD(now)} - Recargando hábitos');
        _lastLoadDate = now;

        if (mounted) {
          context.read<HabitBloc>().add(LoadHabits());
        }
      }
    }
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
      VibrationService.error(); // Vibración de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: () {
              VibrationService.selection();
              context.read<HabitBloc>().add(LoadHabits());
            },
          ),
        ),
      );
    }

    // Vibración suave cuando los hábitos se cargan exitosamente
    if (state is HabitLoaded && state.habits.isNotEmpty && !state.isRefreshing) {
      VibrationService.selection();
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
        onRetry: () {
          VibrationService.medium();
          context.read<HabitBloc>().add(LoadHabits());
        },
      ),
      HabitLoaded() => RefreshIndicator(
        onRefresh: _handlePullToRefresh,
        child: _LoadedView(
          state: state,
          todayEntriesMap: _getTodayEntriesMap(state.weekEntries),
          onToggle: _handleToggle,
          onDelete: _handleDelete,
          onAdd: _handleAdd,
        ),
      ),
      _ => const _LoadingView(),
    };
  }

  /// Pull-to-refresh: sincronización completa con la nube. El indicador
  /// gira hasta que el bloc termina de refrescar.
  Future<void> _handlePullToRefresh() async {
    final bloc = context.read<HabitBloc>();
    bloc.add(PullToRefresh());
    await bloc.stream
        .firstWhere((s) => s is! HabitLoaded || !s.isRefreshing)
        .timeout(const Duration(seconds: 20), onTimeout: () => bloc.state);
  }

  Map<int, HabitStatus> _getTodayEntriesMap(List<HabitEntry> weekEntries) {
    final today = DateTime.now();
    return {
      for (final entry in weekEntries)
        if (AppDateUtils.isSameDay(entry.date, today))
          entry.habitId: entry.status,
    };
  }

  void _handleToggle(int habitId, HabitStatus currentStatus) {
    final today = DateTime.now();
    context.read<HabitBloc>().add(
      ToggleHabitEntryEvent(
        habitId: habitId,
        date: today,
        currentStatus: currentStatus,
      ),
    );
    WidgetUpdater.refreshWeeklyHabitsWidget();
  }

  void _handleDelete(int habitId, String habitName) {
    // Usar el método estático del diálogo que incluye vibración
    DeleteConfirmationDialog.show(
      context,
      habitName: habitName,
      onConfirm: () {
        context.read<HabitBloc>().add(DeleteHabitEvent(habitId));
        WidgetUpdater.refreshWeeklyHabitsWidget();
        
        // Vibración de confirmación después de eliminar
        VibrationService.success();
        
        // Mostrar feedback al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hábito "$habitName" eliminado'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _handleAdd() {
    VibrationService.medium(); // Vibración al abrir el bottom sheet
    AddHabitBottomSheet.show(
      context,
      onAdd: (habitName) {
        context.read<HabitBloc>().add(CreateHabitEvent(habitName));
        WidgetUpdater.refreshWeeklyHabitsWidget();
        
        // Vibración de éxito al crear
        VibrationService.success();
        
        // Feedback al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hábito "$habitName" creado'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Preparando tus hábitos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Construyendo una mejor versión de ti',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(child: _ErrorContent(message: message, onRetry: onRetry)),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorContent({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
  final void Function(int, String) onDelete;
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
            physics: const AlwaysScrollableScrollPhysics(),
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