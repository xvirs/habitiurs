import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_datasource.dart';
import '../models/habit_model.dart';
import '../models/habit_entry_model.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitLocalDataSource localDataSource;

  HabitRepositoryImpl(this.localDataSource);

  @override
  Future<List<Habit>> getAllHabits() async {
    return await localDataSource.getAllHabits();
  }

  @override
  Future<int> createHabit(Habit habit) async {
    final habitModel = HabitModel.fromEntity(habit);
    return await localDataSource.insertHabit(habitModel);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final habitModel = HabitModel.fromEntity(habit);
    await localDataSource.updateHabit(habitModel);
  }

  @override
  Future<void> deleteHabit(int id) async {
    await localDataSource.permanentlyDeleteHabit(id);
  }

  @override
  Future<List<HabitEntry>> getHabitEntriesForWeek(DateTime startOfWeek) async {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return await localDataSource.getHabitEntriesForDateRange(startOfWeek, endOfWeek);
  }

  @override
  Future<HabitEntry?> getHabitEntryForDate(int habitId, DateTime date) async {
    return await localDataSource.getHabitEntryForDate(habitId, date);
  }

  @override
  Future<void> updateHabitEntryStatus(int habitId, DateTime date, HabitStatus status) async {
    final existingEntry = await localDataSource.getHabitEntryForDate(habitId, date);
    
    if (existingEntry != null) {
      if (status == HabitStatus.pending) {
        await localDataSource.deleteHabitEntry(habitId, date);
      } else {
        final updatedEntry = HabitEntryModel(
          id: existingEntry.id,
          habitId: habitId,
          date: date,
          status: status,
        );
        await localDataSource.updateHabitEntry(updatedEntry);
      }
    } else if (status != HabitStatus.pending) {
      final newEntry = HabitEntryModel(
        habitId: habitId,
        date: date,
        status: status,
      );
      await localDataSource.insertHabitEntry(newEntry);
    }
  }
}