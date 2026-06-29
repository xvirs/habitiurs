import 'package:equatable/equatable.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../domain/entities/habit.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object> get props => [];
}

class LoadHabits extends HabitEvent {}

// REMOVIDO: class LoadHabitsWithSync extends HabitEvent {}

class CreateHabitEvent extends HabitEvent {
  final String name;
  final int colorValue;
  final String iconKey;
  final List<int> weekdays;
  final String? reminderTime;

  const CreateHabitEvent(
    this.name, {
    this.colorValue = Habit.defaultColor,
    this.iconKey = Habit.defaultIcon,
    this.weekdays = Habit.allWeekdays,
    this.reminderTime,
  });

  @override
  List<Object> get props => [
    name,
    colorValue,
    iconKey,
    weekdays,
    reminderTime ?? '',
  ];
}

/// Actualiza propiedades del hábito (renombrar, personalizar, archivar).
class UpdateHabitEvent extends HabitEvent {
  final Habit habit;

  const UpdateHabitEvent(this.habit);

  @override
  List<Object> get props => [habit];
}

/// Archiva (archived=true) o restaura (archived=false) un hábito.
class SetHabitArchivedEvent extends HabitEvent {
  final Habit habit;
  final bool archived;

  const SetHabitArchivedEvent(this.habit, this.archived);

  @override
  List<Object> get props => [habit, archived];
}

class ToggleHabitEntryEvent extends HabitEvent {
  final int habitId;
  final DateTime date;
  final HabitStatus currentStatus;

  const ToggleHabitEntryEvent({
    required this.habitId,
    required this.date,
    required this.currentStatus,
  });

  @override
  List<Object> get props => [habitId, date, currentStatus];
}

class DeleteHabitEvent extends HabitEvent {
  final int habitId;

  const DeleteHabitEvent(this.habitId);

  @override
  List<Object> get props => [habitId];
}

class RefreshData extends HabitEvent {}

class PullToRefresh extends HabitEvent {
  const PullToRefresh();
}

class RescheduleNotifications extends HabitEvent {}

class UpdatePastHabitEntryEvent extends HabitEvent {
  final int habitId;
  final DateTime date;
  final HabitStatus newStatus;

  const UpdatePastHabitEntryEvent({
    required this.habitId,
    required this.date,
    required this.newStatus,
  });

  @override
  List<Object> get props => [habitId, date, newStatus];
}
