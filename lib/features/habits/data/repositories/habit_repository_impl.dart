// lib/features/habits/data/repositories/habit_repository_impl.dart - MODIFICADO

import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_datasource.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../core/sync/repositories/sync_repository.dart'; // Importar SyncRepository
import '../../../../core/auth/interfaces/i_auth_service.dart'; // Para obtener el userId

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;
  final SyncRepository _syncRepository;
  final IAuthService _authService;

  HabitRepositoryImpl(this.localDataSource, this._syncRepository, this._authService);

  @override
  Future<List<Habit>> getAllHabits() async {
    // La UI solo debería mostrar hábitos activos
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
  // ✅ MODIFICADO: Implementación de la eliminación lógica
  Future<void> deleteHabit(int id, String userId) async {
    print('🔄 [HabitRepo] Iniciando soft delete para hábito ID: $id');
    // 1. Marcar como inactivo en la base de datos local
    await localDataSource.deleteHabit(id); // Este método ya marca is_active = 0
    print('✅ [HabitRepo] Hábito $id marcado inactivo localmente.');

    // 2. Marcar como inactivo en Firebase
    try {
      await _syncRepository.markHabitAsInactive(userId, id);
      print('✅ [HabitRepo] Hábito $id marcado inactivo en Firebase.');
    } catch (e) {
      print('❌ [HabitRepo] Error marcando hábito $id como inactivo en Firebase: $e');
      // No rethrow para que el soft delete local no falle si Firebase falla
    }
  }

  // ✅ ELIMINADO: Este método ya no es parte de la interfaz y no se usará.
  // Future<void> permanentlyDeleteHabit(int id) async {
  //   // ... (código anterior de eliminación física)
  // }


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
    final existingEntry = await localDataSource.getHabitEntryForDate(habitId, date);

    if (existingEntry != null) {
      final updatedEntry = HabitEntryModel(
        id: existingEntry.id, 
        habitId: habitId,
        date: date,
        status: status, 
      );
      await localDataSource.updateHabitEntry(updatedEntry);
      
    } else {
      if (status != HabitStatus.pending) {
        final newEntry = HabitEntryModel(
          habitId: habitId,
          date: date,
          status: status,
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