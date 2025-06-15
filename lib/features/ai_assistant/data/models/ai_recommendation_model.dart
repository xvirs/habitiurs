// lib/features/ai_assistant/data/models/ai_recommendation_model.dart


import 'package:habitiurs/features/ai_assistant/domain/entities/educational_content.dart';

class AIRecommendationModel extends AIRecommendation {
  const AIRecommendationModel({
    required super.id,
    required super.content,
    required super.timestamp,
    required super.type,
    super.isFromAI = true,
    super.context,
  });

  factory AIRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AIRecommendationModel(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: RecommendationType.values.firstWhere(
        (e) => e.toString() == 'RecommendationType.${json['type']}',
        orElse: () => RecommendationType.general,
      ),
      isFromAI: json['is_from_ai'] as bool? ?? true,
      context: json['context'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'is_from_ai': isFromAI,
      'context': context,
    };
  }
}