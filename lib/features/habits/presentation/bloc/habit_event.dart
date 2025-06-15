import 'package:equatable/equatable.dart';
import '../../../../shared/enums/habit_status.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object> get props => [];
}

class LoadHabits extends HabitEvent {}

class CreateHabitEvent extends HabitEvent {
  final String name;

  const CreateHabitEvent(this.name);

  @override
  List<Object> get props => [name];
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