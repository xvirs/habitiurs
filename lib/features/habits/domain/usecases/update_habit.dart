import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

/// Actualiza las propiedades de un hábito (nombre, color, icono,
/// frecuencia, recordatorio o estado de archivado).
class UpdateHabit {
  final HabitRepository repository;

  UpdateHabit(this.repository);

  Future<void> call(Habit habit) async {
    assert(habit.id != null, 'El hábito debe tener id para actualizarse');
    await repository.updateHabit(habit);
  }
}
