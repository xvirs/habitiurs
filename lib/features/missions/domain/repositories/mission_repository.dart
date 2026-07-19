import '../entities/mission.dart';

abstract class MissionRepository {
  Future<List<Mission>> getAllMissions();
  Future<int> createMission(Mission mission);
  Future<void> updateMission(Mission mission);
  Future<void> deleteMission(int id, String userId);
}
