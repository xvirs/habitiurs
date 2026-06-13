import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class CreateHabit {
  final HabitRepository repository;

  CreateHabit(this.repository);

  Future<int> call(Habit habit) async {
    final id = await repository.createHabit(habit);
    return id;
  }
}
