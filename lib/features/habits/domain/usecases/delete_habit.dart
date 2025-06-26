import '../repositories/habit_repository.dart';
import '../../../../core/auth/interfaces/i_auth_service.dart';

class DeleteHabit {
  final HabitRepository repository;
  final IAuthService authService;

  DeleteHabit(this.repository, this.authService);

  Future<void> call(int habitId) async {
    final userId = authService.currentUser?.id;
    if (userId == null) {
      return;
    }
    await repository.deleteHabit(habitId, userId);
  }
}
