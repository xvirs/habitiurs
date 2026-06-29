import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool isActive;

  /// Color ARGB del hábito (ver HabitAppearance.colors).
  final int colorValue;

  /// Clave del icono dentro de HabitAppearance.icons.
  final String iconKey;

  /// Días de la semana programados, ISO 8601 (1 = lunes … 7 = domingo).
  /// Un hábito diario contiene los 7 días.
  final List<int> weekdays;

  /// Hora del recordatorio propio en formato 'HH:mm', o null si no tiene.
  final String? reminderTime;

  const Habit({
    this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
    this.colorValue = defaultColor,
    this.iconKey = defaultIcon,
    this.weekdays = allWeekdays,
    this.reminderTime,
  });

  static const int defaultColor = 0xFF1565C0;
  static const String defaultIcon = 'check';
  static const List<int> allWeekdays = [1, 2, 3, 4, 5, 6, 7];

  bool get isDaily => weekdays.length == 7;

  /// Si el hábito está programado para la fecha dada.
  bool isScheduledOn(DateTime date) => weekdays.contains(date.weekday);

  Habit copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
    int? colorValue,
    String? iconKey,
    List<int>? weekdays,
    String? reminderTime,
    bool clearReminder = false,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      weekdays: weekdays ?? this.weekdays,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    createdAt,
    isActive,
    colorValue,
    iconKey,
    weekdays,
    reminderTime,
  ];

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, isActive: $isActive, '
        'weekdays: $weekdays, reminder: $reminderTime)';
  }
}
