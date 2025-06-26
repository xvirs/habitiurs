import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    int? id,
    required String name,
    required DateTime createdAt,
    bool isActive = true,
  }) : super(
          id: id,
          name: name,
          createdAt: createdAt,
          isActive: isActive,
        );

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: (json['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  HabitModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      createdAt: habit.createdAt,
      isActive: habit.isActive,
    );
  }

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      createdAt: createdAt,
      isActive: isActive,
    );
  }

  @override
  String toString() {
    return 'HabitModel(id: $id, name: $name, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitModel &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        isActive.hashCode;
  }
}
