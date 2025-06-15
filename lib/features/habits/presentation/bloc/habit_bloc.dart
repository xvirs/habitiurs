// lib/features/habits/presentation/bloc/habit_bloc.dart - CORREGIDO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/usecases/get_all_habits.dart';
import '../../domain/usecases/create_habit.dart';
import '../../domain/usecases/get_week_entries.dart';
import '../../domain/usecases/toggle_habit_entry.dart';
import '../../domain/usecases/delete_habit.dart';
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
  }

  Future<void> _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) async {
    emit(HabitLoading());
    try {
      await _loadAndEmitData(emit);
    } catch (e) {
      emit(HabitError('Error cargando hábitos: ${e.toString()}'));
    }
  }

  Future<void> _onCreateHabit(CreateHabitEvent event, Emitter<HabitState> emit) async {
    try {
      await _createHabit(event.name);
      add(RefreshData());
    } catch (e) {
      emit(HabitError('Error creando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onToggleHabitEntry(ToggleHabitEntryEvent event, Emitter<HabitState> emit) async {
    try {
      await _toggleHabitEntry(event.habitId, event.date, event.currentStatus);
      add(RefreshData());
    } catch (e) {
      emit(HabitError('Error actualizando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitState> emit) async {
    try {
      await _deleteHabit(event.habitId);
      add(RefreshData());
    } catch (e) {
      emit(HabitError('Error eliminando hábito: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<HabitState> emit) async {
    if (state is HabitLoaded) {
      try {
        await _loadAndEmitData(emit);
      } catch (e) {
        emit(HabitError('Error actualizando datos: ${e.toString()}'));
      }
    }
  }

  Future<void> _loadAndEmitData(Emitter<HabitState> emit) async {
    final habits = await _getAllHabits();
    final now = DateTime.now();
    final weekEntries = await _getWeekEntries(now);
    final currentWeekStart = AppDateUtils.getStartOfWeek(now);

    emit(HabitLoaded(
      habits: habits,
      weekEntries: weekEntries,
      currentWeekStart: currentWeekStart,
    ));
  }
}