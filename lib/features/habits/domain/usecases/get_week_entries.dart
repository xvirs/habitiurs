// lib/features/habits/domain/usecases/get_week_entries.dart 
import '../entities/habit_entry.dart';
import '../repositories/habit_repository.dart';
import '../../../../shared/utils/date_utils.dart' as app_date_utils;

class GetWeekEntries {
  final HabitRepository repository;

  GetWeekEntries(this.repository);

  Future<List<HabitEntry>> call(DateTime date) async {
    final startOfWeek = app_date_utils.AppDateUtils.getStartOfWeek(date);
    return await repository.getHabitEntriesForWeek(startOfWeek);
  }
}