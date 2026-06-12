import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';

class UpdateHabitStatus {
  final HabitRepository repository;

  UpdateHabitStatus(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus status) async {
    final dateStr = date.toIso8601String().split('T')[0];
    print('🔄 [UpdateHabitStatus] habitId: $habitId, fecha: $dateStr → ${status.name}');
    await repository.updateHabitEntryStatus(habitId, date, status);
    print('✅ [UpdateHabitStatus] Estado actualizado: habitId=$habitId, $dateStr → ${status.name}');
  }
}
