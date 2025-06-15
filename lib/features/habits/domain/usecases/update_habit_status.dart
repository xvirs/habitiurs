import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';

class UpdateHabitStatus {
  final HabitRepository repository;

  UpdateHabitStatus(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus status) async {
    await repository.updateHabitEntryStatus(habitId, date, status);
  }
}