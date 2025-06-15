import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';

class ToggleHabitEntry {
  final HabitRepository repository;

  ToggleHabitEntry(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus currentStatus) async {
    // Lógica para alternar entre los 3 estados
    HabitStatus nextStatus;
    
    print('🔄 UseCase: Current status received: ${currentStatus.toString()}');
    
    switch (currentStatus) {
      case HabitStatus.pending:
        nextStatus = HabitStatus.completed;
        break;
      case HabitStatus.completed:
        nextStatus = HabitStatus.skipped;
        break;
      case HabitStatus.skipped:
        nextStatus = HabitStatus.pending;
        break;
    }
    
    print('🔄 UseCase: Next status will be: ${nextStatus.toString()}');
    
    await repository.updateHabitEntryStatus(habitId, date, nextStatus);
    
    print('✅ UseCase: Status updated in repository');
  }
}