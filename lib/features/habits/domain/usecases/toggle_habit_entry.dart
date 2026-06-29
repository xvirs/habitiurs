import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class ToggleHabitEntry {
  final HabitRepository repository;

  ToggleHabitEntry(this.repository);

  Future<void> call(
    int habitId,
    DateTime date,
    HabitStatus currentStatus,
  ) async {
    final today = DateTime.now();
    final isToday = AppDateUtils.isSameDay(date, today);

    if (!isToday) {
      appLog(
        '⚠️ [ToggleHabitEntry] Ignorado: la fecha no es hoy (habitId: $habitId)',
      );
      return;
    }

    HabitStatus nextStatus;

    switch (currentStatus) {
      case HabitStatus.pending:
        nextStatus = HabitStatus.completed;
        break;
      case HabitStatus.completed:
        nextStatus = HabitStatus.pending;
        break;
      case HabitStatus.skipped:
        nextStatus = HabitStatus.completed;
        break;
    }

    appLog(
      '🔄 [ToggleHabitEntry] Hábito $habitId: ${currentStatus.name} → ${nextStatus.name}',
    );
    await repository.updateHabitEntryStatus(habitId, date, nextStatus);
    appLog(
      '✅ [ToggleHabitEntry] Estado actualizado: habitId=$habitId → ${nextStatus.name}',
    );
  }
}
