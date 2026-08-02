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
  final bool isRefreshing;

  /// Racha actual (días consecutivos completados) por habitId. Un hábito
  /// solo corta racha en los días en que está programado.
  final Map<int, int> streaks;

  const HabitLoaded({
    required this.habits,
    required this.weekEntries,
    required this.currentWeekStart,
    this.isRefreshing = false,
    this.streaks = const {},
  });

  @override
  List<Object> get props => [
    habits,
    weekEntries,
    currentWeekStart,
    isRefreshing,
    streaks,
  ];

  HabitLoaded copyWith({
    List<Habit>? habits,
    List<HabitEntry>? weekEntries,
    DateTime? currentWeekStart,
    bool? isRefreshing,
    Map<int, int>? streaks,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      weekEntries: weekEntries ?? this.weekEntries,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      streaks: streaks ?? this.streaks,
    );
  }
}

class HabitError extends HabitState {
  final String message;

  const HabitError(this.message);

  @override
  List<Object> get props => [message];
}
