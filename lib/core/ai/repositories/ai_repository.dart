import 'package:habitiurs/core/ai/models/ai_response_model.dart';
import '../models/ai_request_model.dart';
import '../services/gemini_service.dart';
import '../services/ai_fallback_service.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class AIRepository {
  final GeminiService _geminiService;
  final AIFallbackService _fallbackService;

  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;

  AIRepository._internal()
    : _geminiService = GeminiService(),
      _fallbackService = AIFallbackService();

  /// Método principal para cualquier request de IA.
  /// La `request` ya debe contener el prompt construido y la metadata relevante.
  Future<AIResponse> generateResponse(AIRequest request) async {
    try {
      final hasConnection = await _geminiService.checkConnectivity();

      if (hasConnection) {
        try {
          final response = await _geminiService.generateContent(request);
          return response;
        } catch (e) {
          // Log solo si es un error crítico (no rate limit)
          if (!e.toString().contains('Límite de API')) {
            appLog('⚠️ [AIRepository] Gemini API error: $e');
          }
          return await _fallbackService.generateFallbackResponse(request);
        }
      } else {
        return await _fallbackService.generateFallbackResponse(request);
      }
    } catch (e) {
      appLog('❌ [AIRepository] Critical error: $e');
      return await _fallbackService.generateFallbackResponse(request);
    }
  }

  /// Método genérico para la evaluación de hábitos.
  /// El prompt debe ser construido por la feature de hábitos.
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

  /// Método genérico para análisis de patrones de hábitos.
  /// El prompt y la metadata deben ser construidos por la feature de hábitos.
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

  /// Método genérico para sugerir mejoras en hábitos.
  /// El prompt y la metadata deben ser construidos por la feature de hábitos.
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

  /// Método genérico para análisis de tendencias de estadísticas.
  /// El prompt y la metadata deben ser construidos por la feature de estadísticas.
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

  /// Método genérico para predicción de éxito de hábitos.
  /// El prompt y la metadata deben ser construidos por la feature de estadísticas.
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

  /// Método genérico para análisis de patrones de tendencia.
  /// El prompt y la metadata deben ser construidos por la feature de estadísticas.
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

  /// Método genérico para obtener recomendación personalizada de IA.
  /// El prompt y la metadata deben ser construidos por la feature de AI Assistant.
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

  /// Método genérico para obtener un mensaje motivacional.
  /// El prompt y la metadata deben ser construidos por la feature de AI Assistant.
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

  // Eliminados todos los métodos _buildXyzPrompt.

  Future<bool> hasInternetConnection() async {
    return await _geminiService.checkConnectivity();
  }

  void dispose() {
    _geminiService.dispose();
  }
}
