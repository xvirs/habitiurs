class DatabaseConstants {
  static const String databaseName = 'habitiurs.db';
  static const int databaseVersion = 5; // <--- ¡INCREMENTADO A LA VERSIÓN 5!

  static const String habitsTable = 'habits';
  static const String habitEntriesTable = 'habit_entries';

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
      last_modified TEXT,
      FOREIGN KEY (habit_id) REFERENCES $habitsTable (id),
      UNIQUE(habit_id, date)
    )
  ''';

  static const String createTempHabitEntriesTable = '''
    CREATE TABLE habit_entries_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      last_modified TEXT,
      FOREIGN KEY (habit_id) REFERENCES $habitsTable (id),
      UNIQUE(habit_id, date)
    )
  ''';

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

  static const String copyHabitEntriesData = '''
    INSERT INTO habit_entries_new (id, habit_id, date, status, last_modified)
    SELECT id, habit_id, date, status, NULL FROM habit_entries
  ''';

  static const String addLastModifiedColumnToHabitEntries = '''
    ALTER TABLE $habitEntriesTable ADD COLUMN last_modified TEXT;
  ''';
}