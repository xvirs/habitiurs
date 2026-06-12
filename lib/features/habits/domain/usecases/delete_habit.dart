// lib/features/habits/domain/usecases/delete_habit.dart
import '../repositories/habit_repository.dart';
import '../../../../core/auth/interfaces/i_auth_service.dart';

class DeleteHabit {
  final HabitRepository repository;
  final IAuthService authService; // Inyección del servicio de autenticación

  DeleteHabit(this.repository, this.authService);

  Future<void> call(int habitId) async {
    final userId = authService.currentUser?.id;
    if (userId == null) {
      print('⚠️ [DeleteHabit Usecase] No user ID available. No se puede realizar la eliminación remota.');
      // Lanzar una excepción específica o un mensaje de error si es un escenario no permitido.
      throw Exception('Usuario no autenticado para eliminar hábitos remotamente.');
    }
    // Llama al repositorio para eliminar el hábito, pasando el userId.
    await repository.deleteHabit(habitId, userId);
  }
}
