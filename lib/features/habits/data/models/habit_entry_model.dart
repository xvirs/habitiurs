// lib/features/habits/data/models/habit_entry_model.dart - COMPLETO CON MÉTODOS FALTANTES
import '../../domain/entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitEntryModel extends HabitEntry {
  const HabitEntryModel({
    int? id,
    required int habitId,
    required DateTime date,
    required HabitStatus status,
  }) : super(
          id: id,
          habitId: habitId,
          date: date,
          status: status,
        );

  // ✅ MÉTODO fromJson FALTANTE
  factory HabitEntryModel.fromJson(Map<String, dynamic> json) {
    return HabitEntryModel(
      id: json['id'] as int?,
      habitId: json['habit_id'] as int,
      date: DateTime.parse(json['date'] as String),
      status: HabitStatus.values[json['status'] as int],
    );
  }

  // ✅ MÉTODO toJson FALTANTE
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0], // Solo YYYY-MM-DD
      'status': status.index,
    };
  }

  // ✅ MÉTODO copyWith FALTANTE
  HabitEntryModel copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    HabitStatus? status,
  }) {
    return HabitEntryModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  // ✅ MÉTODO fromEntity FALTANTE
  factory HabitEntryModel.fromEntity(HabitEntry entry) {
    return HabitEntryModel(
      id: entry.id,
      habitId: entry.habitId,
      date: entry.date,
      status: entry.status,
    );
  }

  // ✅ MÉTODO toEntity FALTANTE
  HabitEntry toEntity() {
    return HabitEntry(
      id: id,
      habitId: habitId,
      date: date,
      status: status,
    );
  }

  @override
  String toString() {
    return 'HabitEntryModel(id: $id, habitId: $habitId, date: ${date.toIso8601String().split('T')[0]}, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitEntryModel &&
        other.id == id &&
        other.habitId == habitId &&
        other.date.day == date.day &&
        other.date.month == date.month &&
        other.date.year == date.year &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        habitId.hashCode ^
        date.day.hashCode ^
        date.month.hashCode ^
        date.year.hashCode ^
        status.hashCode;
  }
}