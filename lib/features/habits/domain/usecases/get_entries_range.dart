import '../entities/habit_entry.dart';
import '../repositories/habit_repository.dart';

/// Entradas de un rango de fechas. Lo usa el cálculo de rachas, que necesita
/// mirar más atrás que la semana visible.
class GetEntriesRange {
  final HabitRepository repository;

  GetEntriesRange(this.repository);

  Future<List<HabitEntry>> call(DateTime start, DateTime end) =>
      repository.getHabitEntriesForDateRange(start, end);
}
