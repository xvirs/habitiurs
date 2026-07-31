import 'package:habitiurs/core/utils/app_logger.dart';
import '../../../../core/auth/interfaces/i_auth_service.dart';
import '../repositories/mission_repository.dart';

class DeleteMission {
  final MissionRepository repository;
  final IAuthService authService;

  DeleteMission(this.repository, this.authService);

  Future<void> call(int missionId) async {
    // Los invitados pueden borrar localmente aunque no sincronicen: usamos
    // string vacío como userId y el borrado remoto (best-effort) simplemente
    // fallará silenciosamente para ellos.
    final userId = authService.currentUser?.id ?? '';
    if (userId.isEmpty) {
      appLog(
        'ℹ️ [DeleteMission] Sin usuario: borrado solo local (sin propagar).',
      );
    }
    await repository.deleteMission(missionId, userId);
  }
}
