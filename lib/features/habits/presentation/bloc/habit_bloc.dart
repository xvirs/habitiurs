import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/usecases/get_all_habits.dart';
import '../../domain/usecases/create_habit.dart';
import '../../domain/usecases/get_week_entries.dart';
import '../../domain/usecases/toggle_habit_entry.dart';
import '../../domain/usecases/delete_habit.dart';
import '../../../../core/di/injection_container.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetAllHabits _getAllHabits;
  final CreateHabit _createHabit;
  final GetWeekEntries _getWeekEntries;
  final ToggleHabitEntry _toggleHabitEntry;
  final DeleteHabit _deleteHabit;

  HabitBloc({
    required GetAllHabits getAllHabits,
    required CreateHabit createHabit,
    required GetWeekEntries getWeekEntries,
    required ToggleHabitEntry toggleHabitEntry,
    required DeleteHabit deleteHabit,
  })  : _getAllHabits = getAllHabits,
        _createHabit = createHabit,
        _getWeekEntries = getWeekEntries,
        _toggleHabitEntry = toggleHabitEntry,
        _deleteHabit = deleteHabit, // Corregido: de 'deleteHabiet' a 'deleteHabit'
        super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<CreateHabitEvent>(_onCreateHabit);
    on<ToggleHabitEntryEvent>(_onToggleHabitEntry);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<RefreshData>(_onRefreshData);
    on<PullToRefresh>(_onPullToRefresh);
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    print('🔄 HabitBloc: Iniciando carga de hábitos...');
    emit(HabitLoading());
    try {
      await _loadAndEmitData(emit);
      print('✅ HabitBloc: Hábitos cargados exitosamente.');
    } catch (e) {
      print('❌ HabitBloc: Error al cargar hábitos: $e');
      emit(HabitError('Error cargando hábitos: ${e.toString()}'));
    }
  }

  Future<void> _onCreateHabit(CreateHabitEvent event, Emitter<HabitState> emit) async {
    print('🔄 HabitBloc: Creando hábito "${event.name}"...');
    try {
      await _createHabit(event.name);
      print('✅ HabitBloc: Hábito "${event.name}" creado localmente.');
      await _loadAndEmitData(emit);
      _syncInBackground('create_habit');
      print('✅ HabitBloc: Datos recargados después de crear hábito.');
    } catch (e) {
      print('❌ HabitBloc: Error al crear hábito "${event.name}": $e');
      emit(HabitError('Error creando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onToggleHabitEntry(ToggleHabitEntryEvent event, Emitter<HabitState> emit) async {
    print('🔄 HabitBloc: Alternando estado de entrada para hábito ${event.habitId} en ${event.date.toIso8601String().split('T')[0]} a ${event.currentStatus.name}...');
    try {
      await _toggleHabitEntry(event.habitId, event.date, event.currentStatus);
      print('✅ HabitBloc: Estado de entrada actualizado localmente.');
      await _loadAndEmitData(emit);
      _syncInBackground('toggle_entry');
      print('✅ HabitBloc: Datos recargados después de alternar entrada.');
    } catch (e) {
      print('❌ HabitBloc: Error al actualizar entrada de hábito ${event.habitId}: $e');
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitState> emit) async {
    print('🔄 HabitBloc: Eliminando hábito ${event.habitId}...');
    try {
      await _deleteHabit(event.habitId);
      print('✅ HabitBloc: Hábito ${event.habitId} eliminado localmente (soft delete).');
      await _loadAndEmitData(emit);
      _syncInBackground('delete_habit');
      print('✅ HabitBloc: Datos recargados después de eliminar hábito.');
    } catch (e) {
      print('❌ HabitBloc: Error al eliminar hábito ${event.habitId}: $e');
      emit(HabitError('Error eliminando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      print('🔄 HabitBloc: Refrescando datos locales...');
      try {
        await _loadAndEmitData(emit);
        print('✅ HabitBloc: Datos locales refrescados.');
      } catch (e) {
        print('❌ HabitBloc: Error al refrescar datos locales: $e');
        emit(HabitError('Error actualizando datos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onPullToRefresh(PullToRefresh event, Emitter<HabitState> emit) async {
    print('🔄 HabitBloc: Iniciando Pull-to-Refresh (sincronización completa)...');
    try {
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: true));
        print('ℹ️ HabitBloc: Emitting isRefreshing state.');
      }
      final syncSuccess = await _performFullSync();
      print('✅ HabitBloc: Sincronización completa finalizada. Éxito: $syncSuccess');
      await _loadAndEmitData(emit, isRefreshing: false);
      print('✅ HabitBloc: Datos recargados después de Pull-to-Refresh.');
    } catch (e) {
      print('❌ HabitBloc: Error durante Pull-to-Refresh: $e');
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        emit(HabitError('Error actualizando desde la nube: ${e.toString()}'));
      }
    }
  }

  Future<bool> _performFullSync() async {
    print('🔄 HabitBloc: Realizando sincronización completa con el repositorio...');
    try {
      final syncRepo = InjectionContainer().syncRepository;
      final success = await syncRepo.syncAll();
      print('✅ HabitBloc: Sincronización completa del repositorio exitosa: $success');
      return success;
    } catch (e) {
      print('❌ HabitBloc: Error en _performFullSync: $e');
      return false;
    }
  }

  void _syncInBackground(String action) {
    print('🔄 HabitBloc: Iniciando sincronización en segundo plano para acción: $action');
    _performBackgroundSync(action).then((success) {
      print('✅ HabitBloc: Sincronización en segundo plano para "$action" completada. Éxito: $success');
    }).catchError((error) {
      print('❌ HabitBloc: Error en sincronización en segundo plano para "$action": $error');
    });
  }

  Future<bool> _performBackgroundSync(String action) async {
    try {
      final syncRepo = InjectionContainer().syncRepository;
      print('ℹ️ HabitBloc: Verificando conexión para sincronización en segundo plano...');
      final hasConnection = await syncRepo.hasInternetConnection();
      if (!hasConnection) {
        print('⚠️ HabitBloc: Sin conexión a internet, omitiendo sincronización en segundo plano.');
        return false;
      }

      switch (action) {
        case 'create_habit':
        case 'delete_habit':
          print('🔄 HabitBloc: Sincronizando solo hábitos en segundo plano.');
          return await syncRepo.syncHabitsOnly();
        case 'toggle_entry':
          print('🔄 HabitBloc: Sincronizando solo entradas en segundo plano.');
          return await syncRepo.syncEntriesOnly();
        default:
          print('🔄 HabitBloc: Sincronizando todo en segundo plano (acción por defecto).');
          return await syncRepo.syncAll();
      }
    } catch (e) {
      print('❌ HabitBloc: Error en _performBackgroundSync: $e');
      return false;
    }
  }

  Future<void> _loadAndEmitData(Emitter<HabitState> emit, {bool isRefreshing = false}) async {
    print('🔄 HabitBloc: Cargando datos de hábitos y entradas para emitir estado...');
    final habits = await _getAllHabits();
    final now = DateTime.now();
    final weekEntries = await _getWeekEntries(now);
    final currentWeekStart = AppDateUtils.getStartOfWeek(now);

    emit(HabitLoaded(
      habits: habits,
      weekEntries: weekEntries,
      currentWeekStart: currentWeekStart,
      isRefreshing: isRefreshing,
    ));
    print('✅ HabitBloc: Datos emitidos (Hábitos: ${habits.length}, Entradas: ${weekEntries.length}).');
  }
}
