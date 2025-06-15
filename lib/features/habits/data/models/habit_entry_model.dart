
import 'package:habitiurs/shared/enums/habit_status.dart';
import '../../domain/entities/habit_entry.dart';

class HabitEntryModel extends HabitEntry {
  const HabitEntryModel({
    super.id,
    required super.habitId,
    required super.date,
    super.status = HabitStatus.pending,
  });

  factory HabitEntryModel.fromMap(Map<String, dynamic> map) {
    // CORREGIDO: Ahora maneja tanto INTEGER como STRING
    final statusValue = map['status'];
    HabitStatus status;
    
    if (statusValue is int) {
      // Si es INTEGER (nuevo formato)
      status = HabitStatus.values[statusValue];
    } else if (statusValue is String) {
      // Si es STRING (formato anterior, por compatibilidad)
      status = HabitStatus.fromString(statusValue);
    } else {
      // Default
      status = HabitStatus.pending;
    }
    
    return HabitEntryModel(
      id: map['id'] as int?,
      habitId: map['habit_id'] as int,
      date: DateTime.parse(map['date'] as String),
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0],
      'status': status.index, // CORREGIDO: Usar índice INTEGER
    };
  }

  factory HabitEntryModel.fromEntity(HabitEntry entry) {
    return HabitEntryModel(
      id: entry.id,
      habitId: entry.habitId,
      date: entry.date,
      status: entry.status,
    );
  }
}