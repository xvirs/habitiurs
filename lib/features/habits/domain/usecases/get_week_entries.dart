import '../entities/habit_entry.dart';
import '../repositories/habit_repository.dart';
import '../../../../shared/utils/date_utils.dart';

class GetWeekEntries {
  final HabitRepository repository;

  GetWeekEntries(this.repository);

  Future<List<HabitEntry>> call(DateTime date) async {
    final startOfWeek = AppDateUtils.getStartOfWeek(date);
    print('🔄 [GetWeekEntries] Semana desde: ${startOfWeek.toIso8601String().split('T')[0]}');
    final entries = await repository.getHabitEntriesForWeek(startOfWeek);
    print('📅 [GetWeekEntries] ${entries.length} entrada(s) obtenida(s)');
    return entries;
  }
}
