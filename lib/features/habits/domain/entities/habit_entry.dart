import 'package:equatable/equatable.dart';
import 'package:habitiurs/shared/enums/habit_status.dart';

class HabitEntry extends Equatable {
  final int? id;
  final int habitId;
  final DateTime date;
  final HabitStatus status;

  const HabitEntry({
    this.id,
    required this.habitId,
    required this.date,
    this.status = HabitStatus.pending,
  });

  bool get completed => status == HabitStatus.completed;

  @override
  List<Object?> get props => [id, habitId, date, status];
}