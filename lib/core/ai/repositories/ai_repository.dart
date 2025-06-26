import 'package:habitiurs/core/ai/models/ai_response_model.dart';
import '../models/ai_request_model.dart';
import '../services/gemini_service.dart';
import '../services/ai_fallback_service.dart';

class AIRepository {
  final GeminiService _geminiService;
  final AIFallbackService _fallbackService;
  
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  
  AIRepository._internal() 
      : _geminiService = GeminiService(),
        _fallbackService = AIFallbackService();

  Future<AIResponse> generateResponse(AIRequest request) async {
    try {
      final hasConnection = await _geminiService.checkConnectivity();
      
      if (hasConnection) {
        try {
          return await _geminiService.generateContent(request);
        } catch (e) {
          return await _fallbackService.generateFallbackResponse(request);
        }
      } else {
        return await _fallbackService.generateFallbackResponse(request);
      }
    } catch (e) {
      return await _fallbackService.generateFallbackResponse(request);
    }
  }

  Future<AIResponse> evaluateHabit({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.habitEvaluation,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> analyzeHabitPatterns({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.habitAnalysis,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> suggestHabitImprovements({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.habitSuggestion,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> analyzeStatisticsTrends({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.statisticsAnalysis,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> predictHabitSuccess({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.successPrediction,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> analyzeTrendPatterns({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.trendAnalysis,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> getPersonalizedRecommendation({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.personalRecommendation,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> getMotivationalMessage({
    required String prompt, 
    required Map<String, dynamic> metadata,
  }) async {
    final request = AIRequest(
      type: AIRequestType.motivationalMessage,
      prompt: prompt,
      metadata: metadata,
    );
    return await generateResponse(request);
  }

  Future<bool> hasInternetConnection() async {
    return await _geminiService.checkConnectivity();
  }

  void dispose() {
    _geminiService.dispose();
  }
}
