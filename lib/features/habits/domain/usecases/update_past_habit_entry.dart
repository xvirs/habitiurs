import '../repositories/habit_repository.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class UpdatePastHabitEntry {
  final HabitRepository repository;

  UpdatePastHabitEntry(this.repository);

  Future<void> call(int habitId, DateTime date, HabitStatus newStatus) async {
    final isToday = AppDateUtils.isToday(date);
    final isFuture = AppDateUtils.isFutureDate(date);
    final dateStr = date.toIso8601String().split('T')[0];

    if (isToday || isFuture) {
      appLog(
        '❌ [UpdatePastHabitEntry] Fecha inválida para edición histórica: $dateStr',
      );
      throw Exception('Solo se puede modificar el estado de días pasados');
    }

    appLog(
      '🔄 [UpdatePastHabitEntry] Editando día pasado — habitId: $habitId, fecha: $dateStr → ${newStatus.name}',
    );
    await repository.updateHabitEntryStatus(habitId, date, newStatus);
    appLog(
      '✅ [UpdatePastHabitEntry] Entrada actualizada: habitId=$habitId, $dateStr → ${newStatus.name}',
    );
  }
}
