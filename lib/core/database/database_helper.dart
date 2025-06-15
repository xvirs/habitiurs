// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/database_constants.dart';

abstract class DatabaseHelper {
  Future<Database> get database;
  Future<void> close();
}

class SqliteDatabaseHelper implements DatabaseHelper {
  static final SqliteDatabaseHelper _instance = SqliteDatabaseHelper._internal();
  static Database? _database;

  SqliteDatabaseHelper._internal();

  factory SqliteDatabaseHelper() => _instance;

  @override
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), DatabaseConstants.databaseName);
    
    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute(DatabaseConstants.createHabitsTable);
    await db.execute(DatabaseConstants.createHabitEntriesTable);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }
    if (oldVersion < 3) {
      await _migrateToVersion3(db);
    }
  }

  Future<void> _migrateToVersion2(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final hasCompletedColumn = result.any((column) => column['name'] == 'completed');
      
      if (hasCompletedColumn) {
        await _migrateCompletedToStatus(db);
      }
    } catch (e) {
      // Si hay error, recrear tabla
      await _recreateHabitEntriesTable(db);
    }
  }

  // NUEVA migración a versión 3: convertir status de TEXT a INTEGER
  Future<void> _migrateToVersion3(Database db) async {
    try {
      // Verificar si status es TEXT y convertir a INTEGER
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final statusColumn = result.firstWhere(
        (column) => column['name'] == 'status',
        orElse: () => <String, dynamic>{},
      );
      
      if (statusColumn.isNotEmpty) {
        // Actualizar valores TEXT a INTEGER
        await db.execute(DatabaseConstants.migrateStatusToInteger);
        
        // Recrear tabla con tipo correcto
        await db.execute(DatabaseConstants.createTempHabitEntriesTable);
        await db.execute(DatabaseConstants.copyHabitEntriesData);
        await db.execute('DROP TABLE habit_entries');
        await db.execute('ALTER TABLE habit_entries_new RENAME TO habit_entries');
      }
    } catch (e) {
      print('Error en migración v3: $e');
      // Si hay error, recrear tabla completa
      await _recreateHabitEntriesTable(db);
    }
  }

  Future<void> _migrateCompletedToStatus(Database db) async {
    await db.execute('ALTER TABLE habit_entries ADD COLUMN status INTEGER DEFAULT 0');
    
    await db.execute('''
      UPDATE habit_entries 
      SET status = CASE 
        WHEN completed = 1 THEN 1 
        ELSE 0 
      END
    ''');
    
    await db.execute(DatabaseConstants.createTempHabitEntriesTable);
    await db.execute(DatabaseConstants.copyHabitEntriesData);
    await db.execute('DROP TABLE habit_entries');
    await db.execute('ALTER TABLE habit_entries_new RENAME TO habit_entries');
  }

  Future<void> _recreateHabitEntriesTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS habit_entries');
    await db.execute(DatabaseConstants.createHabitEntriesTable);
  }
}