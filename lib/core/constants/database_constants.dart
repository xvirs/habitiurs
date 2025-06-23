// lib/core/constants/database_constants.dart
class DatabaseConstants {
  static const String databaseName = 'habitiurs.db';
  static const int databaseVersion = 4; // ✅ MODIFICADO: Incrementar la versión de la base de datos

  // Table names
  static const String habitsTable = 'habits';
  static const String habitEntriesTable = 'habit_entries';

  // Create table queries 
  static const String createHabitsTable = '''
    CREATE TABLE $habitsTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''';

  static const String createHabitEntriesTable = '''
    CREATE TABLE $habitEntriesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      last_modified TEXT, -- ✅ NUEVO: Columna para el timestamp de última modificación
      FOREIGN KEY (habit_id) REFERENCES $habitsTable (id),
      UNIQUE(habit_id, date)
    )
  ''';

  // Esta tabla temporal también debe reflejar el nuevo esquema
  static const String createTempHabitEntriesTable = '''
    CREATE TABLE habit_entries_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      last_modified TEXT, -- ✅ NUEVO: Columna para el timestamp de última modificación
      FOREIGN KEY (habit_id) REFERENCES $habitsTable (id),
      UNIQUE(habit_id, date)
    )
  ''';

  // NUEVA migración para convertir TEXT a INTEGER
  static const String migrateStatusToInteger = '''
    UPDATE habit_entries 
    SET status = CASE 
      WHEN status = 'pending' THEN 0
      WHEN status = 'completed' THEN 1
      WHEN status = 'skipped' THEN 2
      ELSE 0
    END
    WHERE typeof(status) = 'text'
  ''';

  // Esta query de copia de datos también debe incluir el nuevo campo
  // Si estás migrando datos antiguos que no tienen 'last_modified', puedes poner NULL
  static const String copyHabitEntriesData = '''
    INSERT INTO habit_entries_new (id, habit_id, date, status, last_modified) -- ✅ MODIFICADO
    SELECT id, habit_id, date, status, NULL FROM habit_entries -- ✅ MODIFICADO: Puedes poner NULL para datos antiguos
  ''';

  // ✅ NUEVO: Query para añadir la columna 'last_modified' si es una migración incremental
  static const String addLastModifiedColumnToHabitEntries = '''
    ALTER TABLE $habitEntriesTable ADD COLUMN last_modified TEXT;
  ''';
}