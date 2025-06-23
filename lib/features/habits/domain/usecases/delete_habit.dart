// lib/features/habits/domain/usecases/delete_habit.dart - MODIFICADO (ÚLTIMA VERSIÓN)

import '../repositories/habit_repository.dart';
import '../../../../core/auth/interfaces/i_auth_service.dart'; // Necesitas IAuthService para obtener el userId
import '../../../../core/di/injection_container.dart'; // Para acceder a AuthService si no se inyecta

class DeleteHabit {
  final HabitRepository repository;
  final IAuthService _authService; 

  DeleteHabit(this.repository, this._authService); 

  Future<void> call(int habitId) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      print('⚠️ [DeleteHabitUseCase] No se puede eliminar el hábito $habitId: Usuario no logueado.');
      return;
    }
    // ✅ CAMBIO CLAVE: Llamar a deleteHabit (que ahora es soft delete)
    await repository.deleteHabit(habitId, userId); 
  }
}