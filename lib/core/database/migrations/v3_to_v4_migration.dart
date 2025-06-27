import 'package:sqflite/sqflite.dart';
import 'migration_strategy.dart';
import 'migration_queries.dart';

class V3ToV4Migration implements MigrationStrategy {
  @override
  int get fromVersion => 3;
  
  @override
  int get toVersion => 4;
  
  @override
  Future<void> migrate(Database db) async {
    print('🔄 [Migration] Adding last_modified column to habit_entries');
    try {
      await db.execute(MigrationQueries.addLastModifiedColumn);
      print('✅ [Migration] V3->V4 completed successfully');
    } catch (e) {
      print('❌ [Migration] V3->V4 failed: $e');
      rethrow;
    }
  }
}