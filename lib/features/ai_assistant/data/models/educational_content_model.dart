// lib/features/ai_assistant/data/models/educational_content_model.dart
// ✅ MANTENER - Solo modelos específicos de la feature

import '../../domain/entities/educational_content.dart';

class EducationalContentModel extends EducationalContent {
  const EducationalContentModel({
    required super.id,
    required super.title,
    required super.content,
    required super.category,
    required super.readTimeMinutes,
    required super.createdAt,
    super.isLocal = false,
  });

  factory EducationalContentModel.fromJson(Map<String, dynamic> json) {
    return EducationalContentModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      readTimeMinutes: json['read_time_minutes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      isLocal: json['is_local'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'read_time_minutes': readTimeMinutes,
      'created_at': createdAt.toIso8601String(),
      'is_local': isLocal,
    };
  }
}