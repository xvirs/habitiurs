import 'package:sqflite/sqflite.dart';
import 'migration_strategy.dart';
import 'migration_queries.dart';

class V1ToV2Migration implements MigrationStrategy {
  @override
  int get fromVersion => 1;
  
  @override
  int get toVersion => 2;
  
  @override
  Future<void> migrate(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final hasCompletedColumn = result.any((column) => column['name'] == 'completed');
      
      if (hasCompletedColumn) {
        await _migrateCompletedToStatus(db);
      }
    } catch (e) {
      print('❌ [Migration] V1->V2 failed: $e. Recreating table.');
      await _recreateHabitEntriesTable(db);
    }
  }
  
  Future<void> _migrateCompletedToStatus(Database db) async {
    await db.execute(MigrationQueries.addCompletedStatusColumn);
    await db.execute(MigrationQueries.migrateCompletedToStatus);
    await db.execute(MigrationQueries.createTempHabitEntriesTable);
    await db.execute(MigrationQueries.copyHabitEntriesData);
    await db.execute(MigrationQueries.dropOldHabitEntriesTable);
    await db.execute(MigrationQueries.renameNewHabitEntriesTable);
  }
  
  Future<void> _recreateHabitEntriesTable(Database db) async {
    await db.execute('DROP TABLE IF EXISTS habit_entries');
    await db.execute('''
      CREATE TABLE habit_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES habits (id),
        UNIQUE(habit_id, date)
      )
    ''');
  }
}