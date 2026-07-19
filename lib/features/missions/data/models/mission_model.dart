import '../../domain/entities/mission.dart';

class MissionModel extends Mission {
  const MissionModel({
    super.id,
    required super.title,
    super.note,
    super.isDone,
    super.dueDate,
    required super.createdAt,
    super.completedAt,
    super.isDeleted,
    super.lastModified,
  });

  /// Acepta tanto filas de sqflite como documentos de Firestore.
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      note: json['note'] as String?,
      isDone: _parseBoolFalseDefault(json['is_done']),
      dueDate: _parseDate(json['due_date']),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: _parseDate(json['completed_at']),
      isDeleted: _parseBoolFalseDefault(json['is_deleted']),
      lastModified: _parseDate(json['last_modified']),
    );
  }

  static bool _parseBoolFalseDefault(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Mapa para sqflite. Si no hay lastModified, usa "ahora".
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'is_done': isDone ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'last_modified': (lastModified ?? DateTime.now()).toIso8601String(),
    };
  }

  /// Mapa para Firestore.
  Map<String, dynamic> toFirestoreMap() => toJson();

  factory MissionModel.fromEntity(Mission mission) {
    return MissionModel(
      id: mission.id,
      title: mission.title,
      note: mission.note,
      isDone: mission.isDone,
      dueDate: mission.dueDate,
      createdAt: mission.createdAt,
      completedAt: mission.completedAt,
      isDeleted: mission.isDeleted,
      lastModified: mission.lastModified,
    );
  }

  Mission toEntity() => this;
}
