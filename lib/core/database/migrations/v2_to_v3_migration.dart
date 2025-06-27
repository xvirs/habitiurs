import 'package:sqflite/sqflite.dart';
import 'migration_strategy.dart';
import 'migration_queries.dart';

class V2ToV3Migration implements MigrationStrategy {
  @override
  int get fromVersion => 2;
  
  @override
  int get toVersion => 3;
  
  @override
  Future<void> migrate(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habit_entries)");
      final statusColumn = result.firstWhere(
        (column) => column['name'] == 'status',
        orElse: () => <String, dynamic>{},
      );
      
      if (statusColumn['type'] == 'TEXT') {
        print('🔄 [Migration] Converting status from TEXT to INTEGER');
        await db.execute(MigrationQueries.convertStatusToInteger);
        await db.execute(MigrationQueries.createTempHabitEntriesTable);
        await db.execute(MigrationQueries.copyHabitEntriesData);
        await db.execute(MigrationQueries.dropOldHabitEntriesTable);
        await db.execute(MigrationQueries.renameNewHabitEntriesTable);
        print('✅ [Migration] V2->V3 completed');
      } else {
        print('ℹ️ [Migration] V2->V3 not needed (status is not TEXT)');
      }
    } catch (e) {
      print('❌ [Migration] V2->V3 failed: $e. Recreating table.');
      await _recreateHabitEntriesTable(db);
    }
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