import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    super.id,
    required super.name,
    required super.createdAt,
    super.isActive,
    super.colorValue,
    super.iconKey,
    super.weekdays,
    super.reminderTime,
  });

  /// Acepta tanto filas de sqflite como documentos de Firestore.
  /// Los campos nuevos son opcionales para compatibilidad con datos viejos.
  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: _parseBool(json['is_active']),
      colorValue: (json['color'] as int?) ?? Habit.defaultColor,
      iconKey: (json['icon'] as String?) ?? Habit.defaultIcon,
      weekdays: parseWeekdays(json['weekdays']),
      reminderTime: json['reminder_time'] as String?,
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return true;
  }

  /// Acepta '1,2,3' (sqflite), [1,2,3] (Firestore) o null (datos viejos).
  static List<int> parseWeekdays(dynamic value) {
    if (value == null) return Habit.allWeekdays;
    if (value is String) {
      if (value.trim().isEmpty) return Habit.allWeekdays;
      final days =
          value
              .split(',')
              .map((d) => int.tryParse(d.trim()))
              .whereType<int>()
              .where((d) => d >= 1 && d <= 7)
              .toList()
            ..sort();
      return days.isEmpty ? Habit.allWeekdays : days;
    }
    if (value is List) {
      final days =
          value
              .map((d) => d is int ? d : int.tryParse(d.toString()))
              .whereType<int>()
              .where((d) => d >= 1 && d <= 7)
              .toList()
            ..sort();
      return days.isEmpty ? Habit.allWeekdays : days;
    }
    return Habit.allWeekdays;
  }

  static String weekdaysToDb(List<int> weekdays) => weekdays.join(',');

  /// Mapa para sqflite.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'color': colorValue,
      'icon': iconKey,
      'weekdays': weekdaysToDb(weekdays),
      'reminder_time': reminderTime,
    };
  }

  /// Mapa para Firestore (weekdays como lista).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'color': colorValue,
      'icon': iconKey,
      'weekdays': weekdays,
      'reminder_time': reminderTime,
    };
  }

  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      createdAt: habit.createdAt,
      isActive: habit.isActive,
      colorValue: habit.colorValue,
      iconKey: habit.iconKey,
      weekdays: habit.weekdays,
      reminderTime: habit.reminderTime,
    );
  }

  Habit toEntity() => this;

  HabitModel copyWithModel({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
    int? colorValue,
    String? iconKey,
    List<int>? weekdays,
    String? reminderTime,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      weekdays: weekdays ?? this.weekdays,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
