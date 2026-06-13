import '../entities/habit.dart';
import '../repositories/habit_repository.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class GetAllHabits {
  final HabitRepository repository;

  GetAllHabits(this.repository);

  Future<List<Habit>> call() async {
    final habits = await repository.getAllHabits();
    appLog('📋 [GetAllHabits] ${habits.length} hábito(s) activo(s) obtenidos');
    return habits;
  }
}
