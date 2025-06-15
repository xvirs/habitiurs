import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<int> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(int id);
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek);
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date);
  Future<void> updateHabitEntryStatus(int habitId, DateTime date, HabitStatus status);
  
}