// lib/features/habits/domain/repositories/habit_repository.dart - MODIFICADO

import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart'; // Asegúrate de que esto esté importado

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<int> createHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  
  // ✅ MODIFICADO: Ahora este método es para el soft delete
  Future<void> deleteHabit(int id, String userId); 

  Future<void> updateHabitEntryStatus(int habitId, DateTime date, HabitStatus status);
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek);
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date);
  Future<List<HabitEntry>> getHabitEntriesForDateRange(DateTime startDate, DateTime endDate);
}