// lib/features/habits/data/datasources/habit_local_datasource.dart - AUTO-SKIP MEJORADO
import 'package:sqflite/sqflite.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/constants/database_constants.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';

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
    
    // Soft delete: Solo marcar como inactivo para preservar estadísticas
    await db.update(
      DatabaseConstants.habitsTable,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await _databaseHelper.database;
    
    // NUEVO: Aplicar auto-skip logic para cualquier consulta de rango
    return await _getEntriesWithAutoSkip(db, startDate, endDate);
  }

  @override
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.habitEntriesTable,
      where: 'habit_id = ? AND date = ?',
      whereArgs: [habitId, _formatDate(date)],
    );
    
    if (maps.isEmpty) {
      // NUEVO: Aplicar auto-skip si es día pasado
      final today = DateTime.now();
      if (AppDateUtils.isPastDate(date) && !AppDateUtils.isSameDay(date, today)) {
        return HabitEntryModel(
          id: null, // No existe en BD
          habitId: habitId,
          date: date,
          status: HabitStatus.skipped,
        );
      }
      return null; // Día actual o futuro sin entrada
    }
    
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

  // MÉTODO PRINCIPAL: Auto-skip logic aplicada automáticamente
  Future<List<HabitEntryModel>> _getEntriesWithAutoSkip(Database db, DateTime startDate, DateTime endDate) async {
    // Obtener todos los hábitos activos
    final habitsQuery = '''
      SELECT id, created_at 
      FROM ${DatabaseConstants.habitsTable} 
      WHERE is_active = 1
    ''';
    final habitsResult = await db.rawQuery(habitsQuery);
    
    final List<HabitEntryModel> entries = [];
    final today = DateTime.now();
    
    for (final habitData in habitsResult) {
      final habitId = habitData['id'] as int;
      final habitCreatedAt = DateTime.parse(habitData['created_at'] as String);
      
      // Generar entradas para cada día del rango
      for (DateTime date = startDate; 
           date.isBefore(endDate.add(const Duration(days: 1))); 
           date = date.add(const Duration(days: 1))) {
        
        // Solo procesar fechas después de la creación del hábito
        if (date.isBefore(DateTime(habitCreatedAt.year, habitCreatedAt.month, habitCreatedAt.day))) {
          continue;
        }
        
        final dateStr = _formatDate(date);
        
        // Buscar entrada existente en BD
        final entryQuery = '''
          SELECT id, habit_id, date, status 
          FROM ${DatabaseConstants.habitEntriesTable} 
          WHERE habit_id = ? AND date = ?
        ''';
        final entryResult = await db.rawQuery(entryQuery, [habitId, dateStr]);
        
        if (entryResult.isNotEmpty) {
          // Entrada existe: usar su estado real
          entries.add(HabitEntryModel.fromMap(entryResult.first));
        } else {
          // No existe entrada: aplicar lógica de auto-skip
          final isToday = AppDateUtils.isSameDay(date, today);
          final isPastDate = AppDateUtils.isPastDate(date) && !isToday;
          
          final status = isPastDate 
              ? HabitStatus.skipped    // Días pasados = automáticamente skipped
              : HabitStatus.pending;   // Día actual/futuro = pendiente
          
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