// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/database_constants.dart'; //

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
      version: DatabaseConstants.databaseVersion, // Asegúrate de que esta versión sea la nueva (ej. 4)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, //
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
    await db.execute(DatabaseConstants.createHabitsTable);
    await db.execute(DatabaseConstants.createHabitEntriesTable);
  }

  @override
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Tus migraciones existentes
    if (oldVersion < 2) { // Migración de v1 a v2 (completed a status)
      await _migrateToVersion2(db);
    }
    if (oldVersion < 3) { // Migración de v2 a v3 (status TEXT a INTEGER)
      await _migrateToVersion3(db);
    }
    // ✅ NUEVA MIGRACIÓN: De la versión 3 a la versión 4 (añadir last_modified)
    if (oldVersion < 4) { // Si la versión anterior es menor que 4
      print('🔄 [Database] Migrando a versión 4: Añadiendo columna last_modified a habit_entries.');
      try {
        await db.execute(DatabaseConstants.addLastModifiedColumnToHabitEntries);
        print('✅ [Database] Columna last_modified añadida exitosamente.');
      } catch (e) {
        print('❌ [Database] Error añadiendo last_modified. Intentando recrear tabla: $e');
        // Si falla (ej. columna ya existe o error inesperado), puedes intentar recrear la tabla
        // Recrear la tabla puede causar pérdida de datos si no se hace con cuidado de copiar.
        // Por la seguridad de los datos, un ALTER TABLE ADD COLUMN es preferible.
        // Si este ALTER TABLE falla, es probable que la columna ya exista o haya un error de SQL.
        // No deberíamos necesitar _recreateHabitEntriesTable aquí si el ALTER es la única adición.
        rethrow; // Relanza el error para depuración si ocurre algo inesperado.
      }
    }
    // Si en el futuro tienes más migraciones, añadirías `if (oldVersion < 5)` y así sucesivamente.
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

  // NUEVA migración a versión 3: convertir status de TEXT a INTEGER
  Future<void> _migrateToVersion3(Database db) async {
    try {
      // Verificar si status es TEXT y convertir a INTEGER
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final statusColumn = result.firstWhere(
        (column) => column['name'] == 'status',
        orElse: () => <String, dynamic>{},
      );
      
      // La condición original era 'if (statusColumn.isNotEmpty)', lo cual es correcto.
      // Esta migración es compleja porque implica mover datos y renombrar.
      // Asegúrate de que las constantes `createTempHabitEntriesTable` y `copyHabitEntriesData`
      // en `DatabaseConstants` tengan también el campo `last_modified` con `NULL` si es una migración limpia.
      
      // ✅ IMPORTANTE: Si ya corriste esta migración a v3 antes, y ahora añades last_modified
      // en la v4, esta parte de v3 *no necesita* modificarse. La columna last_modified
      // se añadirá en la migración a v4.
      if (statusColumn['type'] == 'TEXT') { // Verificar el tipo de columna real
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
    // Este es un proceso de migración de columna booleana a columna de estado.
    // Asegúrate de que si `createTempHabitEntriesTable` y `copyHabitEntriesData` se usan aquí,
    // también consideren la nueva columna `last_modified` (con NULL si aplica).
    await db.execute('ALTER TABLE habit_entries ADD COLUMN status INTEGER DEFAULT 0');
    
    await db.execute('''
      UPDATE habit_entries 
      SET status = CASE 
        WHEN completed = 1 THEN 1 
        ELSE 0 
      END
    ''');
    // Si la columna 'completed' necesita ser eliminada:
    // await db.execute('ALTER TABLE habit_entries DROP COLUMN completed'); 
    
    // Si el esquema final implica recrear la tabla, asegúrate de que use createTempHabitEntriesTable con last_modified
    await db.execute(DatabaseConstants.createTempHabitEntriesTable);
    await db.execute(DatabaseConstants.copyHabitEntriesData);
    await db.execute('DROP TABLE habit_entries');
    await db.execute('ALTER TABLE habit_entries_new RENAME TO habit_entries');
  }

  Future<void> _recreateHabitEntriesTable(Database db) async {
    print('⚠️ [Database] Recreando tabla habit_entries (posible pérdida de datos si no hay respaldo).');
    await db.execute('DROP TABLE IF EXISTS habit_entries');
    await db.execute(DatabaseConstants.createHabitEntriesTable); // Asegúrate que esta constante ya incluye 'last_modified'
  }
}