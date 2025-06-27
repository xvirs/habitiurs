import 'package:sqflite/sqflite.dart';

abstract class MigrationStrategy {
  int get fromVersion;
  int get toVersion;
  Future<void> migrate(Database db);
  
  bool canMigrate(int currentVersion, int targetVersion) {
    return currentVersion == fromVersion && targetVersion >= toVersion;
  }
}

class MigrationManager {
  final List<MigrationStrategy> _migrations = [];
  
  void registerMigration(MigrationStrategy migration) {
    _migrations.add(migration);
  }
  
  Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
    int currentVersion = oldVersion;
    
    while (currentVersion < newVersion) {
      final migration = _findMigration(currentVersion, newVersion);
      
      if (migration == null) {
        throw Exception('No migration found from version $currentVersion');
      }
      
      print('🔄 [Migration] Running migration from v${migration.fromVersion} to v${migration.toVersion}');
      await migration.migrate(db);
      currentVersion = migration.toVersion;
    }
  }
  
  MigrationStrategy? _findMigration(int currentVersion, int targetVersion) {
    return _migrations
        .where((m) => m.canMigrate(currentVersion, targetVersion))
        .fold<MigrationStrategy?>(null, (best, current) {
          if (best == null) return current;
          return current.toVersion <= targetVersion && current.toVersion > best.toVersion 
              ? current 
              : best;
        });
  }
}