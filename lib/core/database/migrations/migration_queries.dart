
class MigrationQueries {
  static const String addLastModifiedColumn = '''
    ALTER TABLE habit_entries ADD COLUMN last_modified TEXT;
  ''';
  
  static const String convertStatusToInteger = '''
    UPDATE habit_entries 
    SET status = CASE 
      WHEN status = 'pending' THEN 0
      WHEN status = 'completed' THEN 1
      WHEN status = 'skipped' THEN 2
      ELSE 0
    END
    WHERE typeof(status) = 'text'
  ''';
  
  static const String createTempHabitEntriesTable = '''
    CREATE TABLE habit_entries_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      habit_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      status INTEGER NOT NULL DEFAULT 0,
      last_modified TEXT,
      FOREIGN KEY (habit_id) REFERENCES habits (id),
      UNIQUE(habit_id, date)
    )
  ''';
  
  static const String copyHabitEntriesData = '''
    INSERT INTO habit_entries_new (id, habit_id, date, status, last_modified)
    SELECT id, habit_id, date, status, NULL FROM habit_entries
  ''';
  
  static const String dropOldHabitEntriesTable = 'DROP TABLE habit_entries';
  
  static const String renameNewHabitEntriesTable = '''
    ALTER TABLE habit_entries_new RENAME TO habit_entries
  ''';
  
  static const String addCompletedStatusColumn = '''
    ALTER TABLE habit_entries ADD COLUMN status INTEGER DEFAULT 0
  ''';
  
  static const String migrateCompletedToStatus = '''
    UPDATE habit_entries 
    SET status = CASE 
      WHEN completed = 1 THEN 1 
      ELSE 0 
    END
  ''';
}