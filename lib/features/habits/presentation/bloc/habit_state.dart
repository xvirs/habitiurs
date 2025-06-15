import 'package:equatable/equatable.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_entry.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object> get props => [];
}

class HabitInitial extends HabitState {}

class HabitLoading extends HabitState {}

class HabitLoaded extends HabitState {
  final List<Habit> habits;
  final List<HabitEntry> weekEntries;
  final DateTime currentWeekStart;

  const HabitLoaded({
    required this.habits,
    required this.weekEntries,
    required this.currentWeekStart,
  });

  @override
  List<Object> get props => [habits, weekEntries, currentWeekStart];

  HabitLoaded copyWith({
    List<Habit>? habits,
    List<HabitEntry>? weekEntries,
    DateTime? currentWeekStart,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      weekEntries: weekEntries ?? this.weekEntries,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
    );
  }
}

class HabitError extends HabitState {
  final String message;

  const HabitError(this.message);

  @override
  List<Object> get props => [message];
}