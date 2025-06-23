// lib/features/habits/presentation/bloc/habit_bloc.dart - CON SINCRONIZACIÓN AUTOMÁTICA
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
        _deleteHabit = deleteHabit,
        super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<CreateHabitEvent>(_onCreateHabit);
    on<ToggleHabitEntryEvent>(_onToggleHabitEntry);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<RefreshData>(_onRefreshData);
    on<PullToRefresh>(_onPullToRefresh); // ✅ NUEVO
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      await _loadAndEmitData(emit);
    } catch (e) {
      emit(HabitError('Error cargando hábitos: ${e.toString()}'));
    }
  }

  // ✅ MEJORADO: Crear hábito + sync automático
  Future<void> _onCreateHabit(CreateHabitEvent event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Creando hábito: "${event.name}"');
      
      // 1. Crear hábito localmente
      await _createHabit(event.name);
      print('✅ [HabitBloc] Hábito creado localmente');
      
      // 2. Recargar datos inmediatamente
      await _loadAndEmitData(emit);
      
      // 3. ✅ NUEVO: Sincronizar automáticamente en background
      _syncInBackground('create_habit');
      
    } catch (e) {
      print('❌ [HabitBloc] Error creando hábito: $e');
      emit(HabitError('Error creando hábito: ${e.toString()}'));
    }
  }

  // ✅ MEJORADO: Toggle + sync automático
  Future<void> _onToggleHabitEntry(ToggleHabitEntryEvent event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Toggle hábito ${event.habitId}: ${event.currentStatus.name}');
      
      // 1. Actualizar localmente
      await _toggleHabitEntry(event.habitId, event.date, event.currentStatus);
      print('✅ [HabitBloc] Toggle realizado localmente');
      
      // 2. Recargar datos inmediatamente
      await _loadAndEmitData(emit);
      
      // 3. ✅ NUEVO: Sincronizar automáticamente en background
      _syncInBackground('toggle_entry');
      
    } catch (e) {
      print('❌ [HabitBloc] Error en toggle: $e');
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  // ✅ MEJORADO: Delete + sync automático
  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Eliminando hábito: ${event.habitId}');
      
      // 1. Eliminar localmente
      await _deleteHabit(event.habitId);
      print('✅ [HabitBloc] Hábito eliminado localmente');
      
      // 2. Recargar datos inmediatamente
      await _loadAndEmitData(emit);
      
      // 3. ✅ NUEVO: Sincronizar automáticamente en background
      _syncInBackground('delete_habit');
      
    } catch (e) {
      print('❌ [HabitBloc] Error eliminando hábito: $e');
      emit(HabitError('Error eliminando hábito: ${e.toString()}'));
    }
  }

  // ✅ REFRESH NORMAL: Solo recarga datos locales
  Future<void> _onRefreshData(RefreshData event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      try {
        print('🔄 [HabitBloc] Refrescando datos locales...');
        await _loadAndEmitData(emit);
        print('✅ [HabitBloc] Datos refrescados');
      } catch (e) {
        print('❌ [HabitBloc] Error refrescando: $e');
        emit(HabitError('Error actualizando datos: ${e.toString()}'));
      }
    }
  }

  // ✅ NUEVO: Pull-to-refresh con sincronización completa
  Future<void> _onPullToRefresh(PullToRefresh event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Pull-to-refresh iniciado...');
      
      // Mostrar estado de refreshing si ya hay datos cargados
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: true));
      }
      
      // 1. Sincronizar con Firebase primero
      final syncSuccess = await _performFullSync();
      
      // 2. Recargar datos locales (que ahora incluyen datos de Firebase)
      await _loadAndEmitData(emit, isRefreshing: false);
      
      print('✅ [HabitBloc] Pull-to-refresh completado. Sync: ${syncSuccess ? "exitoso" : "falló"}');
      
    } catch (e) {
      print('❌ [HabitBloc] Error en pull-to-refresh: $e');
      
      // Si hay error, al menos mostrar datos locales
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        emit(HabitError('Error actualizando desde la nube: ${e.toString()}'));
      }
    }
  }

  // ✅ NUEVO: Sincronización completa (para pull-to-refresh)
  Future<bool> _performFullSync() async {
    try {
      print('🔄 [HabitBloc] Realizando sincronización completa...');
      
      final syncRepo = InjectionContainer().syncRepository;
      final success = await syncRepo.syncAll();
      
      print('${success ? "✅" : "❌"} [HabitBloc] Sincronización completa: ${success ? "exitosa" : "falló"}');
      return success;
    } catch (e) {
      print('❌ [HabitBloc] Error en sincronización completa: $e');
      return false;
    }
  }

  // ✅ NUEVO: Sincronización en background (no bloquea UI)
  void _syncInBackground(String action) {
    print('🔄 [HabitBloc] Iniciando sync en background por: $action');
    
    // Ejecutar sync sin await para no bloquear UI
    _performBackgroundSync(action).then((success) {
      print('${success ? "✅" : "⚠️"} [HabitBloc] Background sync por $action: ${success ? "exitoso" : "falló"}');
    }).catchError((error) {
      print('❌ [HabitBloc] Error en background sync por $action: $error');
    });
  }

  // ✅ NUEVO: Sync en background con manejo de errores
  Future<bool> _performBackgroundSync(String action) async {
    try {
      final syncRepo = InjectionContainer().syncRepository;
      
      // Verificar conectividad primero
      final hasConnection = await syncRepo.hasInternetConnection();
      if (!hasConnection) {
        print('⚠️ [HabitBloc] Sin conexión, sync pospuesto');
        return false;
      }
      
      // Realizar sync según el tipo de acción
      switch (action) {
        case 'create_habit':
        case 'delete_habit':
          return await syncRepo.syncHabitsOnly();
        case 'toggle_entry':
          return await syncRepo.syncEntriesOnly();
        default:
          return await syncRepo.syncAll();
      }
    } catch (e) {
      print('❌ [HabitBloc] Error en background sync: $e');
      return false;
    }
  }

  // ✅ MEJORADO: Cargar datos con indicador de refreshing
  Future<void> _loadAndEmitData(Emitter<HabitState> emit, {bool isRefreshing = false}) async {
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
  }
}