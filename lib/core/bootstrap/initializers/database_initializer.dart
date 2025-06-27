import '../../database/database_helper.dart';

class DatabaseInitializer {
  static Future<void> initialize() async {
    final dbHelper = SqliteDatabaseHelper();
    await dbHelper.database;
    print('✅ [Database] SQLite initialized');
  }
  
  static Future<void> migrateIfNeeded() async {
    final dbHelper = SqliteDatabaseHelper();
    final db = await dbHelper.database;
    
    final result = await db.rawQuery('PRAGMA user_version');
    final version = result.first.values.first as int;
    print('📊 [Database] Current version: $version');
    
    if (version < 4) {
      print('🔄 [Database] Migration needed to version 4');
    }
  }
}