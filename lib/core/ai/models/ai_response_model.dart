
import 'package:habitiurs/core/ai/models/ai_request_model.dart';

class AIResponseConfidence {
  final double score;
  final String level;
  final List<String> factors;

  const AIResponseConfidence({
    required this.score,
    required this.level,
    this.factors = const [],
  });

  Map<String, dynamic> toJson() => {
    'score': score,
    'level': level,
    'factors': factors,
  };

  factory AIResponseConfidence.fromJson(Map<String, dynamic> json) =>
      AIResponseConfidence(
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        level: json['level'] as String? ?? 'medium',
        factors: List<String>.from(json['factors'] as List? ?? []),
      );
}

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.name,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
    'is_from_ai': isFromAI,
    'confidence': confidence?.toJson(),
  };

  factory AIResponse.fromJson(Map<String, dynamic> json) => AIResponse(
    id: json['id'] as String,
    content: json['content'] as String,
    type: AIRequestType.values.byName(json['type'] as String),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    timestamp: DateTime.parse(json['timestamp'] as String),
    isFromAI: json['is_from_ai'] as bool? ?? true,
    confidence: json['confidence'] != null
        ? AIResponseConfidence.fromJson(json['confidence'])
        : null,
  );

  factory AIResponse.fallback({
    required String content,
    required AIRequestType type,
    Map<String, dynamic>? metadata,
  }) => AIResponse(
    id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
    content: content,
    type: type,
    metadata: metadata ?? {},
    timestamp: DateTime.now(),
    isFromAI: false,
    confidence: const AIResponseConfidence(
      score: 0.6,
      level: 'medium',
      factors: ['offline_mode', 'template_based'],
    ),
  );
}