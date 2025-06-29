// lib/features/habits/domain/repositories/habit_repository.dart
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart'; // Asegúrate de importar esto

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<int> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  // Se ha actualizado la firma para requerir el userId para la eliminación remota.
  Future<void> deleteHabit(int id, String userId); 
  Future<void> updateHabitEntryStatus(int habitId, DateTime date, HabitStatus status);
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek);
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date);
  Future<List<HabitEntry>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate);
}
