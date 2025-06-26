import '../entities/habit_entry.dart';
import '../repositories/habit_repository.dart';
import '../../../../shared/utils/date_utils.dart';

class GetWeekEntries {
  final HabitRepository repository;

  GetWeekEntries(this.repository);

  Future<List<HabitEntry>> call(DateTime date) async {
    final startOfWeek = AppDateUtils.getStartOfWeek(date);
    return await repository.getHabitEntriesForWeek(startOfWeek);
  }
}
