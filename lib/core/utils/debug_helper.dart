import '../../shared/enums/habit_status.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class DebugHelper {
  static void printHabitStatus(String location, HabitStatus status) {
    appLog('🔍 DEBUG [$location]: Status = ${status.toString()}');
  }

  static void printToggleAction(
    String location,
    int habitId,
    DateTime date,
    HabitStatus currentStatus,
  ) {
    appLog(
      '🔄 TOGGLE [$location]: Habit $habitId, Date ${date.toIso8601String().split('T')[0]}, Current: ${currentStatus.toString()}',
    );
  }
}
