// lib/features/habits/data/repositories/habit_repository_impl.dart
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_datasource.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../core/sync/repositories/sync_repository.dart'; // Asegúrate de importar SyncRepository

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;
  final SyncRepository _syncRepository;

  HabitRepositoryImpl(this.localDataSource, this._syncRepository);

  @override
  Future<List<Habit>> getAllHabits() async {
    return await localDataSource.getAllHabits(includeInactive: false);
  }

  @override
  Future<int> createHabit(Habit habit) async {
    final habitModel = HabitModel.fromEntity(habit);
    return await localDataSource.insertHabit(habitModel);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final habitModel = HabitModel.fromEntity(habit);
    await localDataSource.updateHabit(habitModel);
  }

  @override
  Future<void> deleteHabit(int id, String userId) async {
    try {
      // 1. Eliminar localmente el hábito y sus entradas relacionadas
      await localDataSource.deleteHabit(id); 
      print('✅ [HabitRepository] Hábito $id eliminado localmente.');

      // 2. Solicitar la eliminación remota del hábito.
      // Se utiliza `deleteHabitRemotely` para una eliminación completa en la nube.
      await _syncRepository.deleteHabitRemotely(userId, id);
      print('✅ [HabitRepository] Solicitada eliminación remota para hábito $id.');
    } catch (e, stackTrace) {
      // Captura cualquier error que provenga de la eliminación local o remota
      print('❌ [HabitRepository] Error CRÍTICO al eliminar hábito $id: $e\n$stackTrace');
      rethrow; // Propaga la excepción para que sea manejada por el BLoC
    }
  }

  @override
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek) async {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return await localDataSource.getHabitEntriesForDateRange(startOfWeek, endOfWeek);
  }

  @override
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date) async {
    return await localDataSource.getHabitEntryForDate(habitId, date);
  }

  @override
  Future<void> updateHabitEntryStatus(int habitId, DateTime date, HabitStatus status) async {
    // Normalizar fecha al inicio del día para evitar problemas de precision
    final normalizedDate = AppDateUtils.getStartOfDay(date);

    final existingEntry = await localDataSource.getHabitEntryForDate(habitId, normalizedDate);

    if (existingEntry != null) {
      final updatedEntry = HabitEntryModel(
        id: existingEntry.id,
        habitId: habitId,
        date: normalizedDate,
        status: status,
        lastModified: DateTime.now(),
      );
      await localDataSource.updateHabitEntry(updatedEntry);
    } else {
      // Solo crear entrada si el estado es diferente a pending
      if (status != HabitStatus.pending) {
        final newEntry = HabitEntryModel(
          habitId: habitId,
          date: normalizedDate,
          status: status,
          lastModified: DateTime.now(),
        );
        await localDataSource.insertHabitEntry(newEntry);
      }
    }
  }

  @override
  Future<List<HabitEntry>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate) async {
    return await localDataSource.getHabitEntriesForDateRange(startDate, endDate);
  }
}
