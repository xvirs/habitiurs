enum AIRequestType {
  habitEvaluation,
  habitAnalysis,
  habitSuggestion,
  statisticsAnalysis,
  successPrediction,
  trendAnalysis,
  personalRecommendation,
  generalAdvice,
  motivationalMessage,
}

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

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'prompt': prompt,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRequest &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          prompt == other.prompt &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(type, prompt, timestamp);
}