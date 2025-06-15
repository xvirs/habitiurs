import '../../shared/enums/habit_status.dart';

class DebugHelper {
  static void printHabitStatus(String location, HabitStatus status) {
    print('🔍 DEBUG [$location]: Status = ${status.toString()}');
  }
  
  static void printToggleAction(String location, int habitId, DateTime date, HabitStatus currentStatus) {
    print('🔄 TOGGLE [$location]: Habit $habitId, Date ${date.toIso8601String().split('T')[0]}, Current: ${currentStatus.toString()}');
  }
}