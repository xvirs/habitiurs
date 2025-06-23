// lib/features/habits/domain/usecases/toggle_habit_entry.dart - Se mantiene así
import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';

class ToggleHabitEntry {
  final HabitRepository repository;

  ToggleHabitEntry(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus currentStatus) async {
    final today = DateTime.now();
    final isToday = AppDateUtils.isSameDay(date, today);
    
    // Solo permitir toggle para el día actual
    if (!isToday) {
      print('⚠️ Toggle bloqueado: Solo se puede modificar el día actual');
      return; // No hacer nada si no es el día actual
    }
    
    HabitStatus nextStatus;
    
    switch (currentStatus) {
      case HabitStatus.pending:
        nextStatus = HabitStatus.completed;
        break;
      case HabitStatus.completed:
        nextStatus = HabitStatus.pending; // Este es el camino que desmarca a pendiente
        break;
      case HabitStatus.skipped:
        nextStatus = HabitStatus.completed; 
        break;
    }
    
    print('🔄 UseCase: ${currentStatus.toString()} → ${nextStatus.toString()}');
    
    await repository.updateHabitEntryStatus(habitId, date, nextStatus);
    
    print('✅ UseCase: Status actualizado');
  }
}