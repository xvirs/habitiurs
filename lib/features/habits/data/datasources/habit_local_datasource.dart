import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';

abstract class HabitLocalDataSource {
  Future<List<HabitModel>> getAllHabits({bool includeInactive = false});
  Future<int> insertHabit(HabitModel habit);
  Future<void> insertHabitWithId(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(int id);
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(
      DateTime startDate, DateTime endDate);
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date);
  Future<int> insertHabitEntry(HabitEntryModel entry);
  Future<void> updateHabitEntry(HabitEntryModel entry);
  Future<void> deleteHabitEntry(int habitId, DateTime date);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final DatabaseHelper _databaseHelper;

  HabitLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<List<HabitModel>> getAllHabits({bool includeInactive = false}) async {
    final db = await _databaseHelper.database;
    List<Map<String, dynamic>> maps;

    if (includeInactive) {
      maps = await db.query(
        'habits',
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        'habits',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );
    }
    return List.generate(maps.length, (i) => HabitModel.fromJson(maps[i]));
  }

  @override
  Future<int> insertHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    return await db.insert('habits', habit.toJson());
  }

  @override
  Future<void> insertHabitWithId(HabitModel habit) async {
    final db = await _databaseHelper.database;
    try {
      await db.execute('''
        INSERT OR REPLACE INTO habits (id, name, created_at, is_active)
        VALUES (?, ?, ?, ?)
      ''', [
        habit.id,
        habit.name,
        habit.createdAt.toIso8601String(),
        habit.isActive ? 1 : 0,
      ]);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    await db.update(
      'habits',
      habit.toJson(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'habits',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'habit_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date DESC, habit_id',
    );
    return List.generate(maps.length, (i) => HabitEntryModel.fromJson(maps[i]));
  }

  @override
  Future<HabitEntryModel?> getHabitEntryForDate(
      int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];

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
  }

  @override
  Future<int> insertHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    try {
      final entryJson = entry.toJson();
      entryJson['last_modified'] =
          entry.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String();

      return await db.insert(
        'habit_entries',
        entryJson,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      rethrow;
    }
  }
}
