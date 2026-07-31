import '../entities/mission.dart';
import '../repositories/mission_repository.dart';

class CreateMission {
  final MissionRepository repository;

  CreateMission(this.repository);

  Future<int> call(Mission mission) => repository.createMission(mission);
}
