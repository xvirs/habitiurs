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
import 'package:habitiurs/core/utils/app_logger.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;
  final SyncRepository _syncRepository;

  HabitRepositoryImpl(this.localDataSource, this._syncRepository);

  @override
  Future<List<Habit>> getAllHabits() async {
    final habits = await localDataSource.getAllHabits(includeInactive: false);
    appLog(
      '📋 [HabitRepository] ${habits.length} hábito(s) activo(s) cargados de BD local',
    );
    return habits;
  }

  @override
  Future<List<Habit>> getArchivedHabits() async {
    final habits = await localDataSource.getAllHabits(includeInactive: true);
    return habits.where((h) => !h.isActive).toList();
  }

  @override
  Future<int> createHabit(Habit habit) async {
    appLog('🔄 [HabitRepository] Insertando hábito: "${habit.name}"');
    // Estampar lastModified=ahora: es un cambio del usuario y debe ganar el merge.
    final habitModel = HabitModel.fromEntity(
      habit.copyWith(lastModified: DateTime.now()),
    );
    final id = await localDataSource.insertHabit(habitModel);
    appLog('✅ [HabitRepository] Hábito insertado con ID: $id');
    return id;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    // Estampar lastModified=ahora: cambio del usuario, gana sobre versiones viejas.
    final habitModel = HabitModel.fromEntity(
      habit.copyWith(lastModified: DateTime.now()),
    );
    await localDataSource.updateHabit(habitModel);
  }

  @override
  Future<void> deleteHabit(int id, String userId) async {
    // 1. Eliminar localmente — operación principal, debe completarse siempre
    await localDataSource.deleteHabit(id);
    appLog('✅ [HabitRepository] Hábito $id eliminado localmente.');

    // 2. Eliminar remotamente de forma best-effort (no bloquea, no lanza)
    // Guests y usuarios offline no tienen acceso a Firestore — es correcto ignorar el error.
    // En el próximo syncAll los cambios locales se propagan.
    _syncRepository
        .deleteHabitRemotely(userId, id)
        .then((_) {
          appLog('✅ [HabitRepository] Hábito $id eliminado remotamente.');
        })
        .catchError((e) {
          appLog(
            '⚠️ [HabitRepository] Eliminación remota de hábito $id no completada (se reintentará): $e',
          );
        });
  }

  @override
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek) async {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return await localDataSource.getHabitEntriesForDateRange(
      startOfWeek,
      endOfWeek,
    );
  }

  @override
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date) async {
    return await localDataSource.getHabitEntryForDate(habitId, date);
  }

  @override
  Future<void> updateHabitEntryStatus(
    int habitId,
    DateTime date,
    HabitStatus status,
  ) async {
    // Normalizar fecha al inicio del día para evitar problemas de precision
    final normalizedDate = AppDateUtils.getStartOfDay(date);

    final existingEntry = await localDataSource.getHabitEntryForDate(
      habitId,
      normalizedDate,
    );

    final dateStr = normalizedDate.toIso8601String().split('T')[0];
    appLog(
      '🔄 [HabitRepository] Actualizando entrada — habitId: $habitId, fecha: $dateStr, estado: ${status.name}',
    );

    if (existingEntry != null) {
      final updatedEntry = HabitEntryModel(
        id: existingEntry.id,
        habitId: habitId,
        date: normalizedDate,
        status: status,
        lastModified: DateTime.now(),
      );
      await localDataSource.updateHabitEntry(updatedEntry);
      appLog(
        '✅ [HabitRepository] Entrada actualizada — habitId: $habitId, $dateStr → ${status.name}',
      );
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
        appLog(
          '✅ [HabitRepository] Entrada creada — habitId: $habitId, $dateStr → ${status.name}',
        );
      } else {
        appLog(
          'ℹ️ [HabitRepository] Sin entrada creada — estado pending no requiere registro (habitId: $habitId, $dateStr)',
        );
      }
    }

    // FASE 1: IMPROVED SYNC RELIABILITY
    // Force immediate sync of entries to cloud to prevent data loss if app is closed.
    // We don't await the result to avoid blocking UI, but we trigger it.
    _syncRepository.syncEntriesOnly().then((success) {
      if (!success)
        appLog(
          '⚠️ [HabitRepo] Immediate sync after update failed, will retry later.',
        );
    });
  }

  @override
  Future<List<HabitEntry>> getHabitEntriesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await localDataSource.getHabitEntriesForDateRange(
      startDate,
      endDate,
    );
  }
}
