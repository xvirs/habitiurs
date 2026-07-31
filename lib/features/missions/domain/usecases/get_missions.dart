import '../entities/mission.dart';
import '../repositories/mission_repository.dart';

class GetMissions {
  final MissionRepository repository;

  GetMissions(this.repository);

  Future<List<Mission>> call() => repository.getAllMissions();
}
