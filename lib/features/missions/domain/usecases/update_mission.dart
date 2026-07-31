import '../entities/mission.dart';
import '../repositories/mission_repository.dart';

class UpdateMission {
  final MissionRepository repository;

  UpdateMission(this.repository);

  Future<void> call(Mission mission) => repository.updateMission(mission);
}
