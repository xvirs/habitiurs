import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class GetAllHabits {
  final HabitRepository repository;

  GetAllHabits(this.repository);

  Future<List<Habit>> call() async {
    final habits = await repository.getAllHabits();
    print('📋 [GetAllHabits] ${habits.length} hábito(s) activo(s) obtenidos');
    return habits;
  }
}
