// lib/features/habits/domain/entities/habit_entry.dart
import 'package:equatable/equatable.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitEntry extends Equatable {
  final int? id;
  final int habitId;
  final DateTime date;
  final HabitStatus status;

  const HabitEntry({
    this.id,
    required this.habitId,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [id, habitId, date, status];

  @override
  String toString() {
    return 'HabitEntry(id: $id, habitId: $habitId, date: ${date.toIso8601String().split('T')[0]}, status: ${status.name})';
  }
}