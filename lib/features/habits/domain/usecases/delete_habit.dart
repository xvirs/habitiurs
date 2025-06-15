import '../repositories/habit_repository.dart';

class DeleteHabit {
  final HabitRepository repository;

  DeleteHabit(this.repository);

  Future<void> call(int habitId) async {
    await repository.deleteHabit(habitId);
  }
}