// lib/features/habits/presentation/bloc/habit_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/usecases/get_all_habits.dart';
import '../../domain/usecases/create_habit.dart';
import '../../domain/usecases/get_week_entries.dart';
import '../../domain/usecases/toggle_habit_entry.dart';
import '../../domain/usecases/delete_habit.dart'; // Asegúrate de importar el use case de eliminación
import '../../../../core/di/injection_container.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final GetAllHabits _getAllHabits;
  final CreateHabit _createHabit;
  final GetWeekEntries _getWeekEntries;
  final ToggleHabitEntry _toggleHabitEntry;
  final DeleteHabit _deleteHabit; // Se inyecta el use case de eliminación

  HabitBloc({
    required GetAllHabits getAllHabits,
    required CreateHabit createHabit,
    required GetWeekEntries getWeekEntries,
    required ToggleHabitEntry toggleHabitEntry,
    required DeleteHabit deleteHabit, // Se requiere en el constructor
  })  : _getAllHabits = getAllHabits,
        _createHabit = createHabit,
        _getWeekEntries = getWeekEntries,
        _toggleHabitEntry = toggleHabitEntry,
        _deleteHabit = deleteHabit, // Se asigna la instancia
        super(HabitInitial()) {
    on<LoadHabits>(_onLoadHabits);
    on<CreateHabitEvent>(_onCreateHabit);
    on<ToggleHabitEntryEvent>(_onToggleHabitEntry);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<RefreshData>(_onRefreshData);
    on<PullToRefresh>(_onPullToRefresh);
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      await _loadAndEmitData(emit);
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error al cargar hábitos: $e\n$stackTrace');
      emit(HabitError('Error cargando hábitos: ${e.toString()}'));
    }
  }

  Future<void> _onCreateHabit(CreateHabitEvent event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Creando hábito: "${event.name}"');
      
      await _createHabit(event.name);
      print('✅ [HabitBloc] Hábito creado localmente');
      
      await _loadAndEmitData(emit);
      
      _syncInBackground('create_habit');
      
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error creando hábito: $e\n$stackTrace');
      emit(HabitError('Error creando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onToggleHabitEntry(ToggleHabitEntryEvent event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Toggle hábito ${event.habitId}: ${event.currentStatus.name}');
      
      await _toggleHabitEntry(event.habitId, event.date, event.currentStatus);
      print('✅ [HabitBloc] Toggle realizado localmente');
      
      await _loadAndEmitData(emit);
      
      _syncInBackground('toggle_entry');
      
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error en toggle: $e\n$stackTrace');
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitState> emit) async {
    print('🔄 [HabitBloc] Iniciando eliminación de hábito: ${event.habitId}');
    try {
      await _deleteHabit(event.habitId); 

      print('✅ [HabitBloc] Hábito eliminado localmente y sync remoto solicitado.');
      
      await _loadAndEmitData(emit);
      print('✅ [HabitBloc] UI de hábitos recargada después de eliminación local.');
      
      _syncInBackground('delete_habit');
      print('✅ [HabitBloc] Solicitado sync en background para eliminación remota (desde BLoC).');
      
    } catch (e, stackTrace) { 
      // CAPTURA TODAS LAS EXCEPCIONES DURANTE LA ELIMINACIÓN (locales o remotas)
      print('❌ [HabitBloc] CRITICAL ERROR al eliminar hábito ${event.habitId}: $e\n$stackTrace');
      // Emitir un estado de error para que la UI pueda reaccionar (ej. mostrar un SnackBar)
      if (state is HabitLoaded) {
        // Si estaba cargado, se asegura de que el estado de refresco se desactive
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: false)); 
      }
      emit(HabitError('Error eliminando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      try {
        print('🔄 [HabitBloc] Refrescando datos locales...');
        await _loadAndEmitData(emit);
        print('✅ [HabitBloc] Datos refrescados.');
      } catch (e, stackTrace) {
        print('❌ [HabitBloc] Error refrescando: $e\n$stackTrace');
        emit(HabitError('Error actualizando datos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onPullToRefresh(PullToRefresh event, Emitter<HabitState> emit) async {
    try {
      print('🔄 [HabitBloc] Pull-to-refresh iniciado...');
      
      if (state is HabitLoaded) {
        final currentState = state as HabitLoaded;
        emit(currentState.copyWith(isRefreshing: true));
      } else {
        emit(HabitLoading()); 
      }
      
      final syncSuccess = await _performFullSync();
      
      await _loadAndEmitData(emit, isRefreshing: false);
      
      print('✅ [HabitBloc] Pull-to-refresh completado. Sync: ${syncSuccess ? "exitoso" : "falló"}');
      
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error en pull-to-refresh: $e\n$stackTrace');
      
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
      print('🔄 [HabitBloc] Realizando sincronización completa...');
      
      final syncRepo = InjectionContainer().syncRepository;
      final success = await syncRepo.syncAll();
      
      print('${success ? "✅" : "❌"} [HabitBloc] Sincronización completa: ${success ? "exitosa" : "falló"}');
      return success;
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error en sincronización completa: $e\n$stackTrace');
      return false;
    }
  }

  void _syncInBackground(String action) {
    print('🔄 [HabitBloc] Iniciando sync en background por: $action');
    
    _performBackgroundSync(action).then((success) {
      print('${success ? "✅" : "⚠️"} [HabitBloc] Background sync por $action: ${success ? "exitoso" : "falló"}');
    }).catchError((error, stackTrace) { 
      print('❌ [HabitBloc] Error en background sync por $action: $error\n$stackTrace');
    });
  }

  Future<bool> _performBackgroundSync(String action) async {
    try {
      final syncRepo = InjectionContainer().syncRepository;
      
      final hasConnection = await syncRepo.hasInternetConnection();
      if (!hasConnection) {
        print('⚠️ [HabitBloc] Sin conexión, sync pospuesto');
        return false;
      }
      
      switch (action) {
        case 'create_habit':
        case 'delete_habit':
          return await syncRepo.syncHabitsOnly();
        case 'toggle_entry':
          return await syncRepo.syncEntriesOnly();
        default:
          return await syncRepo.syncAll();
      }
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error en background sync: $e\n$stackTrace');
      return false;
    }
  }

  Future<void> _loadAndEmitData(Emitter<HabitState> emit, {bool isRefreshing = false}) async {
    try { 
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
    } catch (e, stackTrace) {
      print('❌ [HabitBloc] Error en _loadAndEmitData: $e\n$stackTrace');
      rethrow; 
    }
  }
}
