// lib/features/habits/data/models/habit_entry_model.dart - MODIFICADO

import '../../domain/entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitEntryModel extends HabitEntry {
  final DateTime? lastModified; // ✅ NUEVO CAMPO: Timestamp de la última modificación

  const HabitEntryModel({
    int? id,
    required int habitId,
    required DateTime date,
    required HabitStatus status,
    this.lastModified, // ✅ AÑADIR AL CONSTRUCTOR
  }) : super(
          id: id,
          habitId: habitId,
          date: date,
          status: status,
        );

  // ✅ MÉTODO fromJson MODIFICADO
  factory HabitEntryModel.fromJson(Map<String, dynamic> json) {
    return HabitEntryModel(
      id: json['id'] as int?,
      habitId: json['habit_id'] as int,
      date: DateTime.parse(json['date'] as String),
      status: HabitStatus.values[json['status'] as int],
      lastModified: json['last_modified'] != null // ✅ Leer el campo 'last_modified'
          ? DateTime.parse(json['last_modified'] as String)
          : null,
    );
  }

  // ✅ MÉTODO toJson MODIFICADO
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0], // Solo YYYY-MM-DD
      'status': status.index,
      'last_modified': lastModified?.toIso8601String(), // ✅ Escribir el campo 'last_modified'
    };
  }

  // ✅ MÉTODO copyWith MODIFICADO
  HabitEntryModel copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    HabitStatus? status,
    DateTime? lastModified, // ✅ Añadir a copyWith
  }) {
    return HabitEntryModel(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified, // ✅ Copiar el campo
    );
  }

  // ✅ MÉTODO fromEntity MODIFICADO (para incluir lastModified si es un HabitEntryModel)
  factory HabitEntryModel.fromEntity(HabitEntry entry) {
    return HabitEntryModel(
      id: entry.id,
      habitId: entry.habitId,
      date: entry.date,
      status: entry.status,
      // Si HabitEntry no tiene lastModified directamente, asumimos que solo los modelos lo tendrán.
      // Puedes castear si estás seguro de que siempre será un modelo, o manejar como null.
      lastModified: entry is HabitEntryModel ? entry.lastModified : null,
    );
  }

  // ✅ MÉTODO toEntity MODIFICADO (si quieres que HabitEntry también tenga lastModified, aunque no es puramente del dominio)
  // Generalmente, las entidades de dominio no tienen campos de persistencia como lastModified.
  // Si la clase HabitEntry es tu entidad de dominio pura, es mejor no añadir lastModified allí.
  // Mantendremos HabitEntry como pura, y lastModified solo en HabitEntryModel.
  @override // Asegúrate de que esto sobrescriba un método en HabitEntry si lo añades allí.
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
    return 'HabitEntryModel(id: $id, habitId: $habitId, date: ${date.toIso8601String().split('T')[0]}, status: ${status.name}, lastModified: ${lastModified?.toIso8601String() ?? 'null'})'; // ✅ Incluir lastModified en toString
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
        other.status == status &&
        other.lastModified == lastModified; // ✅ Incluir lastModified en comparación
  }

  @override
  int get hashCode {
    return id.hashCode ^
        habitId.hashCode ^
        date.day.hashCode ^
        date.month.hashCode ^
        date.year.hashCode ^
        status.hashCode ^
        lastModified.hashCode; // ✅ Incluir lastModified en hashCode
  }
}