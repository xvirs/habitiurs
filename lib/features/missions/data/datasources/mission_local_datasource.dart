import 'package:sqflite/sqflite.dart';
import 'package:habitiurs/core/utils/app_logger.dart';
import '../../../../core/database/database_helper.dart';
import '../models/mission_model.dart';

abstract class MissionLocalDataSource {
  Future<List<MissionModel>> getAllMissions({bool includeDeleted = false});
  Future<int> insertMission(MissionModel mission);
  Future<void> insertMissionWithId(MissionModel mission);
  Future<void> updateMission(MissionModel mission);
  Future<void> deleteMission(int id);
}

class MissionLocalDataSourceImpl implements MissionLocalDataSource {
  final DatabaseHelper _databaseHelper;

  MissionLocalDataSourceImpl(this._databaseHelper);

  @override
  Future<List<MissionModel>> getAllMissions({
    bool includeDeleted = false,
  }) async {
    final db = await _databaseHelper.database;
    try {
      // Los borrados (tombstones) se excluyen de la UI, pero el sync los pide
      // con includeDeleted=true para propagar la marca de borrado.
      final maps = await db.query(
        'missions',
        where: includeDeleted ? null : 'is_deleted = ?',
        whereArgs: includeDeleted ? null : [0],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => MissionModel.fromJson(maps[i]));
    } catch (e, stackTrace) {
      appLog(
        '❌ [MissionLocalDataSource] Error al obtener misiones: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<int> insertMission(MissionModel mission) async {
    final db = await _databaseHelper.database;
    try {
      return await db.insert('missions', mission.toJson());
    } catch (e, stackTrace) {
      appLog(
        '❌ [MissionLocalDataSource] Error al insertar misión: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> insertMissionWithId(MissionModel mission) async {
    final db = await _databaseHelper.database;
    try {
      final data = mission.toJson();
      data['id'] = mission.id;
      await db.insert(
        'missions',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [MissionLocalDataSource] Error al insertar misión con ID: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateMission(MissionModel mission) async {
    final db = await _databaseHelper.database;
    try {
      await db.update(
        'missions',
        mission.toJson(),
        where: 'id = ?',
        whereArgs: [mission.id],
      );
    } catch (e, stackTrace) {
      appLog(
        '❌ [MissionLocalDataSource] Error al actualizar misión: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteMission(int id) async {
    final db = await _databaseHelper.database;
    try {
      // BORRADO LÓGICO (tombstone): mismo criterio que hábitos para que el
      // borrado se propague por el sync en vez de "resucitar" al re-subir.
      final now = DateTime.now().toIso8601String();
      await db.update(
        'missions',
        {'is_deleted': 1, 'last_modified': now},
        where: 'id = ?',
        whereArgs: [id],
      );
      appLog('DEBUG: Misión $id marcada como borrada (tombstone).');
    } catch (e, stackTrace) {
      appLog(
        '❌ [MissionLocalDataSource] CRITICAL ERROR al eliminar misión $id: $e\n$stackTrace',
      );
      rethrow;
    }
  }
}
