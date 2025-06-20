// lib/features/ai_assistant/data/models/app_guide_model.dart
// ✅ MANTENER - Solo modelos específicos de la feature

import 'package:habitiurs/features/ai_assistant/domain/entities/app_guide.dart';

class AppGuideModel extends AppGuide {
  const AppGuideModel({
    required super.id,
    required super.title,
    required super.content,
    required super.section,
    required super.order,
    super.imageAssets = const [],
  });

  factory AppGuideModel.fromJson(Map<String, dynamic> json) {
    return AppGuideModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      section: json['section'] as String,
      order: json['order'] as int,
      imageAssets: List<String>.from(json['image_assets'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'section': section,
      'order': order,
      'image_assets': imageAssets,
    };
  }
}