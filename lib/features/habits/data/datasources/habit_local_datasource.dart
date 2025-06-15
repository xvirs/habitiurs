// lib/features/habits/data/datasources/habit_local_datasource.dart - CORREGIDO CON SOFT DELETE
import 'package:sqflite/sqflite.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/constants/database_constants.dart';
import '../../../../shared/enums/habit_status.dart';

abstract class HabitLocalDataSource {
  Future<List<HabitModel>> getAllHabits();
  Future<int> insertHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(int id);
  Future<void> permanentlyDeleteHabit(int id);
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate);
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date);
  Future<int> insertHabitEntry(HabitEntryModel entry);
  Future<void> updateHabitEntry(HabitEntryModel entry);
  Future<void> deleteHabitEntry(int habitId, DateTime date);
  
  // AGREGAR: método con auto-skip logic
  Future<List<HabitEntryModel>> getHabitEntriesWithAutoSkip(DateTime startDate, DateTime endDate);
}

class HabitLocalDataSourceImpl implements HabitLocalDataSource {
  final DatabaseHelper _databaseHelper;

  HabitLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<List<HabitModel>> getAllHabits() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.habitsTable,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => HabitModel.fromMap(map)).toList();
  }

  @override
  Future<int> insertHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    return await db.insert(DatabaseConstants.habitsTable, habit.toMap());
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.habitsTable,
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.habitsTable,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> permanentlyDeleteHabit(int id) async {
    final db = await _databaseHelper.database;
    
    // CAMBIO APLICADO: Solo marcar como inactivo, NO eliminar entradas históricas
    await db.update(
      DatabaseConstants.habitsTable,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // COMENTADO: No eliminar las entradas para preservar estadísticas
    // await db.delete(DatabaseConstants.habitEntriesTable, where: 'habit_id = ?', whereArgs: [id]);
    // await db.delete(DatabaseConstants.habitsTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.habitEntriesTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [_formatDate(startDate), _formatDate(endDate)],
      orderBy: 'date ASC, habit_id ASC',
    );
    return maps.map((map) => HabitEntryModel.fromMap(map)).toList();
  }

  @override
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.habitEntriesTable,
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, _formatDate(date)],
    );
    if (maps.isEmpty) return null;
    return HabitEntryModel.fromMap(maps.first);
  }

  @override
  Future<int> insertHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    return await db.insert(
      DatabaseConstants.habitEntriesTable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.habitEntriesTable,
      entry.toMap(),
      where: 'habit_id = ? AND date = ?',
      whereArgs: [entry.habitId, _formatDate(entry.date)],
    );
  }

  @override
  Future<void> deleteHabitEntry(int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseConstants.habitEntriesTable,
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, _formatDate(date)],
    );
  }

  // NUEVO: método con auto-skip logic para Statistics
  @override
  Future<List<HabitEntryModel>> getHabitEntriesWithAutoSkip(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // Obtener todos los hábitos activos
    final habitsQuery = '''
      SELECT id, name, created_at, is_active 
      FROM habits 
      WHERE is_active = 1
    ''';
    final habitsResult = await db.rawQuery(habitsQuery);
    
    // Generar todas las combinaciones de hábito-fecha
    final List<HabitEntryModel> entries = [];
    final today = DateTime.now();
    
    for (final habitData in habitsResult) {
      final habitId = habitData['id'] as int;
      
      // Generar entradas para cada día del rango
      for (DateTime date = startDate; 
           date.isBefore(endDate.add(const Duration(days: 1))); 
           date = date.add(const Duration(days: 1))) {
        
        final dateStr = _formatDate(date);
        
        // Buscar entrada existente
        final entryQuery = '''
          SELECT id, habit_id, date, status 
          FROM habit_entries 
          WHERE habit_id = ? AND date = ?
        ''';
        final entryResult = await db.rawQuery(entryQuery, [habitId, dateStr]);
        
        if (entryResult.isNotEmpty) {
          // Entrada existe, usar su estado
          final entryData = entryResult.first;
          entries.add(HabitEntryModel.fromMap(entryData));
        } else {
          // No existe entrada - aplicar lógica de auto-skip
          final status = date.isBefore(today)
              ? HabitStatus.skipped 
              : HabitStatus.pending;
          
          entries.add(HabitEntryModel(
            id: null, // No existe en BD
            habitId: habitId,
            date: date,
            status: status,
          ));
        }
      }
    }
    
    return entries;
  }

  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}