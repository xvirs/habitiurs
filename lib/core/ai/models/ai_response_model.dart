// lib/core/ai/models/ai_response_model.dart
import 'package:habitiurs/core/ai/models/ai_request_model.dart';

class AIResponse {
  final String id;
  final String content;
  final AIRequestType type;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isFromAI;
  final AIResponseConfidence? confidence;

  const AIResponse({
    required this.id,
    required this.content,
    required this.type,
    this.metadata = const {},
    required this.timestamp,
    this.isFromAI = true,
    this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString(),
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'is_from_ai': isFromAI,
      'confidence': confidence?.toJson(),
    };
  }

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      id: json['id'],
      content: json['content'],
      type: AIRequestType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AIRequestType.generalAdvice,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      isFromAI: json['is_from_ai'] ?? true,
      confidence: json['confidence'] != null 
          ? AIResponseConfidence.fromJson(json['confidence'])
          : null,
    );
  }

  // Compatibilidad con el sistema anterior
  factory AIResponse.fromLegacyRecommendation({
    required String id,
    required String content,
    required DateTime timestamp,
    required bool isFromAI,
    Map<String, dynamic>? context,
  }) {
    return AIResponse(
      id: id,
      content: content,
      type: AIRequestType.personalRecommendation,
      metadata: context ?? {},
      timestamp: timestamp,
      isFromAI: isFromAI,
    );
  }
}

class AIResponseConfidence {
  final double score; // 0.0 - 1.0
  final String level; // 'high', 'medium', 'low'
  final List<String> factors;

  const AIResponseConfidence({
    required this.score,
    required this.level,
    this.factors = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'factors': factors,
    };
  }

  factory AIResponseConfidence.fromJson(Map<String, dynamic> json) {
    return AIResponseConfidence(
      score: json['score']?.toDouble() ?? 0.0,
      level: json['level'] ?? 'medium',
      factors: List<String>.from(json['factors'] ?? []),
    );
  }
}

