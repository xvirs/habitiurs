import '../entities/habit.dart';
import '../repositories/habit_repository.dart';

class CreateHabit {
  final HabitRepository repository;

  CreateHabit(this.repository);

  Future<int> call(String name) async {
    print('🔄 [CreateHabit] Creando hábito: "$name"');
    final habit = Habit(
      name: name,
      createdAt: DateTime.now(),
      isActive: true,
    );
    final id = await repository.createHabit(habit);
    print('✅ [CreateHabit] Hábito creado con ID: $id — "$name"');
    return id;
  }
}
