// lib/features/habits/data/datasources/habit_local_datasource.dart - MODIFICADO (QUITADO permanentlyDeleteHabit, AÑADIDO last_modified en entries)

import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../shared/enums/habit_status.dart'; // Asegúrate de que este import está aquí

abstract class HabitLocalDataSource {
  Future<List<HabitModel>> getAllHabits({bool includeInactive = false}); 
  Future<int> insertHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  // ✅ MODIFICADO: Este método es ahora el ÚNICO para "borrar" un hábito localmente (soft delete)
  Future<void> deleteHabit(int id); 
  // Future<void> permanentlyDeleteHabit(int id); // ✅ ELIMINADO del abstract

  // NUEVO: Insertar hábito con ID específico (para sync)
  Future<void> insertHabitWithId(HabitModel habit);
  
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

  // NUEVO MÉTODO: Insertar hábito con ID específico (para sincronización)
  @override
  Future<void> insertHabitWithId(HabitModel habit) async {
    final db = await _databaseHelper.database;
    
    try {
      // Usar REPLACE para manejar conflictos de ID
      await db.execute('''
        INSERT OR REPLACE INTO habits (id, name, created_at, is_active)
        VALUES (?, ?, ?, ?)
      ''', [
        habit.id,
        habit.name,
        habit.createdAt.toIso8601String(),
        habit.isActive ? 1 : 0,
      ]);
      
      print('✅ [DB] Hábito insertado con ID específico: ${habit.id} - "${habit.name}"');
    } catch (e) {
      print('❌ [DB] Error insertando hábito con ID ${habit.id}: $e');
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
  // ✅ MODIFICADO: Este método es ahora el soft delete local.
  // Su implementación ya era correcta para esto.
  Future<void> deleteHabit(int id) async { 
    final db = await _databaseHelper.database;
    await db.update(
      'habits',
      {'is_active': 0}, // Marca como inactivo
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // @override
  // Future<void> permanentlyDeleteHabit(int id) async { // ✅ ELIMINADO la implementación
  //   // Este método se elimina completamente ya que soft delete será el estándar.
  // }

  @override
  Future<List<HabitEntryModel>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate) async {
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
  Future<HabitEntryModel?> getHabitEntryForDate(int habitId, DateTime date) async {
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
      // ✅ MODIFICADO: Asegurar que last_modified se incluye
      final entryJson = entry.toJson();
      // Si el modelo no trae lastModified (ej. una nueva entrada), usa DateTime.now()
      entryJson['last_modified'] = entry.lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(); 

      final result = await db.insert(
        'habit_entries',
        entryJson, // Usar el JSON con el timestamp
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ [DB] Entrada insertada: Hábito ${entry.habitId} - ${entry.date.toIso8601String().split('T')[0]} - ${entry.status.name}');
      return result;
    } catch (e) {
      print('❌ [DB] Error insertando entrada: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateHabitEntry(HabitEntryModel entry) async {
    final db = await _databaseHelper.database;
    final dateStr = entry.date.toIso8601String().split('T')[0];
    
    try {
      // ✅ MODIFICADO: Asegurar que last_modified se actualiza
      final entryJson = entry.toJson();
      entryJson['last_modified'] = DateTime.now().toIso8601String(); // Siempre actualizar al momento actual al modificar

      final result = await db.update(
        'habit_entries',
        entryJson, // Usar el JSON con el timestamp actualizado
        where: 'habit_id = ? AND date = ?',
        whereArgs: [entry.habitId, dateStr],
      );
      
      if (result > 0) {
        print('✅ [DB] Entrada actualizada: Hábito ${entry.habitId} - $dateStr - ${entry.status.name}');
      } else {
        print('⚠️ [DB] No se encontró entrada para actualizar: Hábito ${entry.habitId} - $dateStr');
      }
    } catch (e) {
      print('❌ [DB] Error actualizando entrada: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteHabitEntry(int habitId, DateTime date) async {
    final db = await _databaseHelper.database;
    final dateStr = date.toIso8601String().split('T')[0];
    
    try {
      final result = await db.delete(
        'habit_entries',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, dateStr],
      );
      
      if (result > 0) {
        print('✅ [DB] Entrada eliminada: Hábito $habitId - $dateStr');
      } else {
        print('⚠️ [DB] No se encontró entrada para eliminar: Hábito $habitId - $dateStr');
      }
    } catch (e) {
      print('❌ [DB] Error eliminando entrada: $e');
      rethrow;
    }
  }
}