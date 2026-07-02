// lib/features/habits/data/datasources/habit_local_datasource.dart
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

abstract class HabitLocalDataSource {
  Future<List<HabitModel>> getAllHabits({
    bool includeInactive = false,
    bool includeDeleted = false,
  });
  Future<int> insertHabit(HabitModel habit);
  Future<void> insertHabitWithId(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(int id);
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date);
  Future<int> insertHabitEntry(HabitEntryModel entry);
  Future<void> updateHabitEntry(HabitEntryModel entry);
  Future<void> deleteHabitEntry(int habitId, DateTime date);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final DatabaseHelper _databaseHelper;

  HabitLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<List<HabitModel>> getAllHabits({
    bool includeInactive = false,
    bool includeDeleted = false,
  }) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;

    try {
      // Los borrados (tombstones) se excluyen de la UI, pero el sync los pide
      // con includeDeleted=true para propagar la marca de borrado.
      final conditions = <String>[];
      final args = <dynamic>[];
      if (!includeDeleted) {
        conditions.add('is_deleted = ?');
        args.add(0);
      }
      if (!includeInactive) {
        conditions.add('is_active = ?');
        args.add(1);
      }
      maps = await db.query(
        'habits',
        where: conditions.isEmpty ? null : conditions.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => HabitModel.fromJson(maps[i]));
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al obtener todos los hábitos: $e\n$stackTrace',
      );
      rethrow; // Re-lanza la excepción para ser capturada por capas superiores
    }
  }

  @override
  Future<int> insertHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    try {
      return await db.insert('habits', habit.toJson());
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al insertar hábito: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> insertHabitWithId(HabitModel habit) async {
    final db = await _databaseHelper.database;
    try {
      await db.execute(
        '''
        INSERT OR REPLACE INTO habits
          (id, name, created_at, is_active, color, icon, weekdays, reminder_time, is_deleted, last_modified)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          habit.id,
          habit.name,
          habit.createdAt.toIso8601String(),
          habit.isActive ? 1 : 0,
          habit.colorValue,
          habit.iconKey,
          HabitModel.weekdaysToDb(habit.weekdays),
          habit.reminderTime,
          habit.isDeleted ? 1 : 0,
          (habit.lastModified ?? DateTime.now()).toIso8601String(),
        ],
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al insertar hábito con ID: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    try {
      await db.update(
        'habits',
        habit.toJson(),
        where: 'id = ?',
        whereArgs: [habit.id],
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al actualizar hábito: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await _databaseHelper.database;
    try {
      // BORRADO LÓGICO (tombstone): en vez de eliminar la fila, la marcamos como
      // borrada con timestamp. Así el borrado se propaga por el sync a los otros
      // dispositivos (con hard delete "resucitaba" al re-subir desde el otro).
      final now = DateTime.now().toIso8601String();
      await db.update(
        'habits',
        {'is_deleted': 1, 'is_active': 0, 'last_modified': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Las entradas del hábito borrado se quedan (inofensivas: el hábito ya no
      // se muestra). No las borramos para no perder historial si se reactiva.
      appLog('DEBUG: Hábito $id marcado como borrado (tombstone).');
    } catch (e, stackTrace) {
      // Se captura cualquier excepción durante la transacción y se relanza
      appLog(
        '❌ [HabitLocalDataSource] CRITICAL ERROR al eliminar hábito $id: $e\n$stackTrace',
      );
      rethrow; // Lanza de nuevo la excepción para que el repositorio pueda manejarla
    }
  }

  @override
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_entries',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date DESC, habit_id',
      );
      return List.generate(
        maps.length,
        (i) => HabitEntryModel.fromJson(maps[i]),
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al obtener entradas para rango de fecha: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<HabitEntryModel?> getHabitEntryForDate(
    int habitId,
    DateTime date,
  ) async {
    final db = await _databaseHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'habit_entries',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dateStr],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return HabitEntryModel.fromJson(maps.first);
      }
      return null;
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al obtener entrada para fecha: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<int> insertHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    try {
      final entryJson = entry.toJson();
      entryJson['last_modified'] =
          entry.lastModified?.toIso8601String() ??
          DateTime.now().toIso8601String();

      return await db.insert(
        'habit_entries',
        entryJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al insertar entrada de hábito: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    final dateStr = entry.date.toIso8601String().split('T')[0];

    try {
      final entryJson = entry.toJson();
      entryJson['last_modified'] = DateTime.now().toIso8601String();

      await db.update(
        'habit_entries',
        entryJson,
        where: 'habit_id = ? AND date = ?',
        whereArgs: [entry.habitId, dateStr],
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al actualizar entrada de hábito: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteHabitEntry(int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];

    try {
      await db.delete(
        'habit_entries',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [HabitLocalDataSource] Error al eliminar entrada de hábito: $e\n$stackTrace',
      );
      rethrow;
    }
  }
}
