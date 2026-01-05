import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';

class UpdatePastHabitEntry {
  final HabitRepository repository;

  UpdatePastHabitEntry(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus newStatus) async {
    // Validar que la fecha NO sea hoy o futuro (solo días pasados)
    final isToday = AppDateUtils.isToday(date);
    final isFuture = AppDateUtils.isFutureDate(date);

    if (isToday || isFuture) {
      throw Exception('Solo se puede modificar el estado de días pasados');
    }

    // Actualizar el estado del hábito
    await repository.updateHabitEntryStatus(habitId, date, newStatus);
  }
}
