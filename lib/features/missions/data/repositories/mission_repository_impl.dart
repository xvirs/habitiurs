import 'package:habitiurs/core/utils/app_logger.dart';
import '../../../../core/sync/repositories/sync_repository.dart';
import '../../domain/entities/mission.dart';
import '../../domain/repositories/mission_repository.dart';
import '../datasources/mission_local_datasource.dart';
import '../models/mission_model.dart';

class MissionRepositoryImpl implements MissionRepository {
  final MissionLocalDataSource localDataSource;
  final SyncRepository _syncRepository;

  MissionRepositoryImpl(this.localDataSource, this._syncRepository);

  @override
  Future<List<Mission>> getAllMissions() async {
    final missions = await localDataSource.getAllMissions();
    appLog('📋 [MissionRepository] ${missions.length} misión(es) cargada(s)');
    return missions;
  }

  @override
  Future<int> createMission(Mission mission) async {
    // Estampar lastModified=ahora: es un cambio del usuario y gana el merge.
    final model = MissionModel.fromEntity(
      mission.copyWith(lastModified: DateTime.now()),
    );
    final id = await localDataSource.insertMission(model);
    appLog('✅ [MissionRepository] Misión insertada con ID: $id');
    return id;
  }

  @override
  Future<void> updateMission(Mission mission) async {
    final model = MissionModel.fromEntity(
      mission.copyWith(lastModified: DateTime.now()),
    );
    await localDataSource.updateMission(model);
  }

  @override
  Future<void> deleteMission(int id, String userId) async {
    // 1. Borrado lógico local — operación principal.
    await localDataSource.deleteMission(id);
    appLog('✅ [MissionRepository] Misión $id eliminada localmente.');

    // 2. Borrado remoto best-effort (no bloquea, no lanza).
    _syncRepository
        .deleteMissionRemotely(userId, id)
        .then((_) {
          appLog('✅ [MissionRepository] Misión $id eliminada remotamente.');
        })
        .catchError((e) {
          appLog(
            '⚠️ [MissionRepository] Borrado remoto de misión $id no completado (se reintentará): $e',
          );
        });
  }
}
