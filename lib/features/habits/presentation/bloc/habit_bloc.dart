// lib/features/habits/presentation/bloc/habit_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/usecases/get_all_habits.dart';
import '../../domain/usecases/create_habit.dart';
import '../../domain/usecases/get_week_entries.dart';
import '../../domain/usecases/toggle_habit_entry.dart';
import '../../domain/usecases/update_past_habit_entry.dart';
import '../../domain/usecases/update_habit.dart';
import '../../domain/usecases/delete_habit.dart';
import '../../domain/services/habit_validation_service.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/notifications/notification_service.dart';
import 'habit_event.dart';
import 'habit_state.dart';
import 'package:habitiurs/core/utils/app_logger.dart';
import 'package:habitiurs/core/home_widget/home_widget_service.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetAllHabits _getAllHabits;
  final CreateHabit _createHabit;
  final GetWeekEntries _getWeekEntries;
  final ToggleHabitEntry _toggleHabitEntry;
  final UpdatePastHabitEntry _updatePastHabitEntry;
  final UpdateHabit _updateHabit;
  final DeleteHabit _deleteHabit;

  HabitBloc({
    required GetAllHabits getAllHabits,
    required CreateHabit createHabit,
    required GetWeekEntries getWeekEntries,
    required ToggleHabitEntry toggleHabitEntry,
    required UpdatePastHabitEntry updatePastHabitEntry,
    required UpdateHabit updateHabit,
    required DeleteHabit deleteHabit,
  }) : _getAllHabits = getAllHabits,
       _createHabit = createHabit,
       _getWeekEntries = getWeekEntries,
       _toggleHabitEntry = toggleHabitEntry,
       _updatePastHabitEntry = updatePastHabitEntry,
       _updateHabit = updateHabit,
       _deleteHabit = deleteHabit,
       super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<CreateHabitEvent>(_onCreateHabit);
    on<UpdateHabitEvent>(_onUpdateHabit);
    on<SetHabitArchivedEvent>(_onSetHabitArchived);
    on<ToggleHabitEntryEvent>(_onToggleHabitEntry);
    on<UpdatePastHabitEntryEvent>(_onUpdatePastHabitEntry);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<RefreshData>(_onRefreshData);
    on<PullToRefresh>(_onPullToRefresh);
    on<RescheduleNotifications>(_onRescheduleNotifications);
  }

  Future<void> _onRescheduleNotifications(
    RescheduleNotifications event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      final currentState = state as HabitLoaded;
      _scheduleDailyNotification(currentState.habits, currentState.weekEntries);
    }
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      await _loadAndEmitData(emit);
    } catch (e) {
      emit(HabitError('Error cargando hábitos: ${e.toString()}'));
    }
  }

  Future<void> _onCreateHabit(
    CreateHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      final habit = Habit(
        name: event.name,
        createdAt: DateTime.now(),
        colorValue: event.colorValue,
        iconKey: event.iconKey,
        weekdays: event.weekdays,
        reminderTime: event.reminderTime,
      );
      final id = await _createHabit(habit);
      await _syncHabitReminder(habit.copyWith(id: id));
      await _loadAndEmitData(emit);
      _syncInBackground('create_habit');
    } catch (e) {
      emit(HabitError('Error creando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabit(
    UpdateHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _updateHabit(event.habit);
      await _syncHabitReminder(event.habit);
      await _loadAndEmitData(emit);
      _syncInBackground('update_habit');
    } catch (e) {
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onSetHabitArchived(
    SetHabitArchivedEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      final updated = event.habit.copyWith(isActive: !event.archived);
      await _updateHabit(updated);
      await _syncHabitReminder(updated);
      await _loadAndEmitData(emit);
      _syncInBackground('update_habit');
    } catch (e) {
      emit(HabitError('Error archivando hábito: ${e.toString()}'));
    }
  }

  /// Programa o cancela el recordatorio propio del hábito según su estado.
  Future<void> _syncHabitReminder(Habit habit) async {
    if (habit.id == null) return;
    try {
      if (habit.isActive && habit.reminderTime != null) {
        await NotificationService().scheduleHabitReminder(
          habitId: habit.id!,
          habitName: habit.name,
          reminderTime: habit.reminderTime!,
          weekdays: habit.weekdays,
        );
      } else {
        await NotificationService().cancelHabitReminder(habit.id!);
      }
    } catch (e) {
      appLog('⚠️ [HabitBloc] Error programando recordatorio de hábito: $e');
    }
  }

  Future<void> _onToggleHabitEntry(
    ToggleHabitEntryEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _toggleHabitEntry(event.habitId, event.date, event.currentStatus);
      await _loadAndEmitData(emit);
      _syncInBackground('toggle_entry');
    } catch (e) {
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePastHabitEntry(
    UpdatePastHabitEntryEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _updatePastHabitEntry(event.habitId, event.date, event.newStatus);
      await _loadAndEmitData(emit);
      _syncInBackground('update_past_entry');
    } catch (e) {
      emit(
        HabitError(
          'Error actualizando hábito del día anterior: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteHabit(
    DeleteHabitEvent event,
    Emitter<HabitState> emit,
  ) async {
    try {
      await _deleteHabit(event.habitId);
      await NotificationService().cancelHabitReminder(event.habitId);
      await _loadAndEmitData(emit);
      _syncInBackground('delete_habit');
    } catch (e) {
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: false));
      }
      emit(HabitError('Error eliminando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<HabitState> emit,
  ) async {
    if (state is HabitLoaded) {
      try {
        await _loadAndEmitData(emit);
      } catch (e) {
        emit(HabitError('Error actualizando datos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onPullToRefresh(
    PullToRefresh event,
    Emitter<HabitState> emit,
  ) async {
    try {
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: true));
      } else {
        emit(HabitLoading());
      }

      await _performFullSync();
      await _loadAndEmitData(emit, isRefreshing: false);
    } catch (e) {
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        emit(HabitError('Error actualizando desde la nube: ${e.toString()}'));
      }
    }
  }

  Future<bool> _performFullSync() async {
    try {
      final syncRepo = InjectionContainer().syncRepository;
      return await syncRepo.syncAll();
    } catch (e) {
      return false;
    }
  }

  void _syncInBackground(String action) {
    _performBackgroundSync(action).catchError((_) => false);
  }

  Future<bool> _performBackgroundSync(String action) async {
    try {
      final syncRepo = InjectionContainer().syncRepository;

      final hasConnection = await syncRepo.hasInternetConnection();
      if (!hasConnection) return false;

      return switch (action) {
        'create_habit' || 'delete_habit' => await syncRepo.syncHabitsOnly(),
        'toggle_entry' => await syncRepo.syncEntriesOnly(),
        _ => await syncRepo.syncAll(),
      };
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadAndEmitData(
    Emitter<HabitState> emit, {
    bool isRefreshing = false,
  }) async {
    final habits = await _getAllHabits();
    final now = DateTime.now();
    final weekEntries = await _getWeekEntries(now);
    final currentWeekStart = AppDateUtils.getStartOfWeek(now);

    // Validar datos antes de emitir
    final validationResult = HabitValidationService.validateWeekData(
      habits,
      weekEntries,
      currentWeekStart,
    );

    // Log warnings si hay
    for (final warning in validationResult.warnings) {
      appLog('⚠️ [HabitBloc] Validation warning: $warning');
    }

    // Si hay errores críticos, emitir error
    if (!validationResult.isValid) {
      final errorMsg =
          'Errores de validación: ${validationResult.issues.join(', ')}';
      appLog('❌ [HabitBloc] Validation errors: $errorMsg');
      emit(HabitError(errorMsg));
      return;
    }

    // Generar entradas faltantes para días pasados (auto-skip)
    final missingEntries = HabitValidationService.generateMissingEntries(
      validationResult.validHabits,
      validationResult.validEntries,
      currentWeekStart,
    );

    // CRÍTICO: Deduplicar entradas antes de emitir
    // Las entradas existentes (de BD) tienen prioridad sobre las generadas
    final entriesMap = <String, HabitEntry>{};

    // Primero agregar las entradas válidas (de BD) - tienen prioridad
    for (final entry in validationResult.validEntries) {
      final key =
          '${entry.habitId}_${AppDateUtils.formatToYYYYMMDD(entry.date)}';
      entriesMap[key] = entry;
    }

    // Luego agregar missing entries SOLO si no existe ya una entrada para esa combinación
    for (final entry in missingEntries) {
      final key =
          '${entry.habitId}_${AppDateUtils.formatToYYYYMMDD(entry.date)}';
      if (!entriesMap.containsKey(key)) {
        entriesMap[key] = entry;
      } else {
        // Log de deduplicación para debugging
        appLog(
          '⚠️ [HabitBloc] Entrada duplicada evitada: habitId=${entry.habitId}, date=${AppDateUtils.formatToYYYYMMDD(entry.date)}',
        );
      }
    }

    final allEntries = entriesMap.values.toList();

    // Programar notificación para hábitos pendientes del día actual
    _scheduleDailyNotification(validationResult.validHabits, allEntries);

    // Exportar los hábitos de hoy a los widgets de pantalla de inicio.
    _exportToHomeWidget(validationResult.validHabits, allEntries, now);

    // Limpiar cache del WeeklyGrid para forzar actualización
    try {
      // Si el import está disponible
      // _StatusCell.clearCache();
    } catch (_) {}

    emit(
      HabitLoaded(
        habits: validationResult.validHabits,
        weekEntries: allEntries,
        currentWeekStart: currentWeekStart,
        isRefreshing: isRefreshing,
      ),
    );
  }

  /// Calcula el estado de hoy de cada hábito y lo manda a los widgets.
  void _exportToHomeWidget(
    List<Habit> habits,
    List<HabitEntry> entries,
    DateTime now,
  ) {
    final todayStatus = <int, HabitStatus>{};
    for (final e in entries) {
      if (e.habitId != 0 && AppDateUtils.isSameDay(e.date, now)) {
        todayStatus[e.habitId] = e.status;
      }
    }
    HomeWidgetService.update(habits, todayStatus);
  }

  /// Programa la notificación diaria con los hábitos pendientes
  void _scheduleDailyNotification(List habits, List entries) {
    _performNotificationScheduling(habits, entries).catchError((error) {
      appLog('⚠️ [HabitBloc] Error programando notificación: $error');
    });
  }

  Future<void> _performNotificationScheduling(List habits, List entries) async {
    try {
      // Obtener configuración de notificaciones
      final settingsRepo = InjectionContainer().settingsRepository;
      final settings = await settingsRepo.getSettings();

      // Si las notificaciones están deshabilitadas, cancelar y salir
      if (!settings.notificationsEnabled) {
        await NotificationService().cancelNotification(0);
        return;
      }

      final today = DateTime.now();
      final todayNormalized = AppDateUtils.getStartOfDay(today);

      // Filtrar hábitos pendientes del día actual
      final pendingHabits = <Map<String, String>>[];

      for (final habit in habits) {
        // Solo cuentan los hábitos programados para hoy
        if (habit is Habit && !habit.isScheduledOn(today)) continue;
        // Buscar la entrada de hoy para este hábito
        final todayEntry =
            entries.where((e) {
              final entryDate = AppDateUtils.getStartOfDay(e.date);
              return e.habitId == habit.id &&
                  entryDate.year == todayNormalized.year &&
                  entryDate.month == todayNormalized.month &&
                  entryDate.day == todayNormalized.day;
            }).firstOrNull;

        // Si no hay entrada o está pendiente, agregarlo
        if (todayEntry == null || todayEntry.status == HabitStatus.pending) {
          pendingHabits.add({'id': habit.id.toString(), 'name': habit.name});
        }
      }

      // Programar notificación si hay hábitos pendientes
      if (pendingHabits.isNotEmpty) {
        final habitNames = pendingHabits.map((h) => h['name']!).toList();
        await NotificationService().scheduleDailyReminder(
          pendingHabitsCount: pendingHabits.length,
          pendingHabitNames: habitNames,
          hour: settings.notificationHour,
          minute: settings.notificationMinute,
        );
      } else {
        // Si no hay hábitos pendientes, cancelar notificación
        NotificationService().cancelNotification(0);
      }
    } catch (e) {
      // Silent fail - no queremos que las notificaciones rompan la app
      appLog('⚠️ [HabitBloc] Error programando notificación: $e');
    }
  }
}
