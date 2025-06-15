import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class CreateHabit {
  final HabitRepository repository;

  CreateHabit(this.repository);

  Future<int> call(String name) async {
    final habit = Habit(
      name: name,
      createdAt: DateTime.now(),
      isActive: true,
    );
    return await repository.createHabit(habit);
  }
}