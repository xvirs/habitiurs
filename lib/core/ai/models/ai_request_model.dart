// lib/core/ai/models/ai_request_model.dart
class AIRequest {
  final AIRequestType type;
  final String prompt;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  AIRequest({
    required this.type,
    required this.prompt,
    this.metadata = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'prompt': prompt,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum AIRequestType {
  // HABITS
  habitEvaluation,
  habitAnalysis,
  habitSuggestion,
  
  // STATISTICS  
  statisticsAnalysis,
  successPrediction,
  trendAnalysis,
  
  // AI ASSISTANT
  personalRecommendation,
  generalAdvice,
  motivationalMessage,
}

