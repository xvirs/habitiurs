// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/database_constants.dart'; //

abstract class DatabaseHelper {
  Future<Database> get database;
  Future<void> close();
  Future<void> clearAllData(); 
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

  @override
  Future<void> clearAllData() async {
    if (_database != null) {
      await _database!.close(); // Cerrar la base de datos primero
      _database = null;
    }
    final path = join(await getDatabasesPath(), DatabaseConstants.databaseName);
    await deleteDatabase(path); // Eliminar el archivo de la base de datos
    print('🗑️ [DatabaseHelper] Base de datos local borrada completamente.');
    // Re-inicializar la base de datos para que esté lista para un nuevo uso
    _database = await _initDatabase();
    print('✅ [DatabaseHelper] Base de datos re-inicializada después de borrar.');
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
    if (oldVersion < 4) {
      print('🔄 [Database] Migrando a versión 4: Añadiendo columna last_modified a habit_entries.');
      try {
        // Las migraciones v2/v3 recrean la tabla desde createTempHabitEntriesTable,
        // que ya incluye last_modified. Solo añadir si la columna no existe.
        final tableInfo = await db.rawQuery("PRAGMA table_info(habit_entries)");
        final hasLastModified = tableInfo.any((col) => col['name'] == 'last_modified');
        if (!hasLastModified) {
          await db.execute(DatabaseConstants.addLastModifiedColumnToHabitEntries);
          print('✅ [Database] Columna last_modified añadida exitosamente.');
        } else {
          print('ℹ️ [Database] Columna last_modified ya existía (creada por migración v2/v3), omitiendo ALTER TABLE.');
        }
      } catch (e) {
        print('❌ [Database] Error en migración v4: $e');
        rethrow;
      }
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
      print('❌ [Database] Error en migración v2: $e. Recreando tabla habit_entries.');
      await _recreateHabitEntriesTable(db);
    }
  }

  Future<void> _migrateToVersion3(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final statusColumn = result.firstWhere(
        (column) => column['name'] == 'status',
        orElse: () => <String, dynamic>{},
      );
      
      if (statusColumn['type'] == 'TEXT') {
        print('🔄 [Database] Migrando a versión 3: Convirtiendo status de TEXT a INTEGER.');
        await db.execute(DatabaseConstants.migrateStatusToInteger);
        await db.execute(DatabaseConstants.createTempHabitEntriesTable);
        await db.execute(DatabaseConstants.copyHabitEntriesData);
        await db.execute('DROP TABLE habit_entries');
        await db.execute('ALTER TABLE habit_entries_new RENAME TO habit_entries');
        print('✅ [Database] Migración a versión 3 completada.');
      } else {
        print('ℹ️ [Database] Migración a versión 3 no necesaria o ya aplicada (status no es TEXT).');
      }

    } catch (e) {
      print('❌ [Database] Error en migración v3: $e. Recreando tabla habit_entries.');
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
    print('⚠️ [Database] Recreando tabla habit_entries (posible pérdida de datos si no hay respaldo).');
    await db.execute('DROP TABLE IF EXISTS habit_entries');
    await db.execute(DatabaseConstants.createHabitEntriesTable);
  }
}
