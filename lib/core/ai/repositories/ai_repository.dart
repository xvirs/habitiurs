// lib/core/ai/repositories/ai_repository.dart - CORREGIDO CON TODOS LOS MÉTODOS
import 'package:habitiurs/core/ai/models/ai_response_model.dart';

import '../models/ai_request_model.dart';
import '../services/gemini_service.dart';
import '../services/ai_fallback_service.dart';

/// Repository central para todas las funcionalidades de IA
class AIRepository {
  final GeminiService _geminiService;
  final AIFallbackService _fallbackService;
  
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  
  AIRepository._internal() 
      : _geminiService = GeminiService(),
        _fallbackService = AIFallbackService();

  /// Método principal que maneja online/offline automáticamente
  Future<AIResponse> generateResponse(AIRequest request) async {
    try {
      // Intentar conectividad
      final hasConnection = await _geminiService.checkConnectivity();
      
      if (hasConnection) {
        try {
          return await _geminiService.generateContent(request);
        } catch (e) {
          print('⚠️ [AI] Gemini falló, usando fallback: $e');
          return await _fallbackService.generateFallbackResponse(request);
        }
      } else {
        print('📵 [AI] Sin conexión, usando fallback');
        return await _fallbackService.generateFallbackResponse(request);
      }
    } catch (e) {
      print('❌ [AI] Error general: $e');
      return await _fallbackService.generateFallbackResponse(request);
    }
  }

  // MÉTODOS ESPECÍFICOS POR FEATURE

  /// HABITS
  Future<AIResponse> evaluateHabit(String habitDescription) async {
    return await _geminiService.evaluateHabit(habitDescription);
  }

  Future<AIResponse> analyzeHabitPatterns(Map<String, dynamic> habitData) async {
    final request = AIRequest(
      type: AIRequestType.habitAnalysis,
      prompt: _buildHabitAnalysisPrompt(habitData),
      metadata: habitData,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> suggestHabitImprovements(Map<String, dynamic> habitData) async {
    final request = AIRequest(
      type: AIRequestType.habitSuggestion,
      prompt: _buildHabitSuggestionPrompt(habitData),
      metadata: habitData,
    );
    return await generateResponse(request);
  }

  /// STATISTICS - ✅ MÉTODOS AGREGADOS
  Future<AIResponse> analyzeStatisticsTrends(Map<String, dynamic> statsData) async {
    final request = AIRequest(
      type: AIRequestType.statisticsAnalysis,
      prompt: _buildStatsAnalysisPrompt(statsData),
      metadata: statsData,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> predictHabitSuccess(Map<String, dynamic> predictionData) async {
    final request = AIRequest(
      type: AIRequestType.successPrediction,
      prompt: _buildPredictionPrompt(predictionData),
      metadata: predictionData,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> analyzeTrendPatterns(Map<String, dynamic> trendData) async {
    final request = AIRequest(
      type: AIRequestType.trendAnalysis,
      prompt: _buildTrendAnalysisPrompt(trendData),
      metadata: trendData,
    );
    return await generateResponse(request);
  }

  /// AI ASSISTANT (mantener compatibilidad)
  Future<AIResponse> getPersonalizedRecommendation(Map<String, dynamic> userContext) async {
    final request = AIRequest(
      type: AIRequestType.personalRecommendation,
      prompt: _buildPersonalRecommendationPrompt(userContext),
      metadata: userContext,
    );
    return await generateResponse(request);
  }

  Future<AIResponse> getMotivationalMessage(Map<String, dynamic> context) async {
    final request = AIRequest(
      type: AIRequestType.motivationalMessage,
      prompt: _buildMotivationalPrompt(context),
      metadata: context,
    );
    return await generateResponse(request);
  }

  // ✅ PROMPT BUILDERS AGREGADOS (los que faltaban del GeminiService)
  String _buildHabitAnalysisPrompt(Map<String, dynamic> habitData) {
    return '''
Analiza estos patrones de hábitos de usuario:

DATOS DEL USUARIO:
${_formatMapForPrompt(habitData)}

Identifica:
1. Patrones de éxito (días/horarios mejores)
2. Obstáculos recurrentes
3. Recomendaciones específicas de mejora

Responde en máximo 4 líneas con insights accionables.
''';
  }

  String _buildHabitSuggestionPrompt(Map<String, dynamic> habitData) {
    return '''
Basándote en estos datos de hábitos:

DATOS:
${_formatMapForPrompt(habitData)}

Sugiere mejoras específicas:
1. Ajustes de rutina
2. Estrategias de motivación
3. Modificaciones de entorno

Máximo 3 líneas, enfoque práctico.
''';
  }

  String _buildStatsAnalysisPrompt(Map<String, dynamic> statsData) {
    return '''
Analiza estas estadísticas de progreso de hábitos:

ESTADÍSTICAS:
${_formatMapForPrompt(statsData)}

Proporciona:
1. Interpretación del progreso actual
2. Tendencias positivas identificadas
3. Áreas de oportunidad específicas
4. Meta realista para el próximo mes

Máximo 4 líneas, enfoque en insights accionables.
''';
  }

  String _buildPredictionPrompt(Map<String, dynamic> predictionData) {
    return '''
Basándote en estos datos históricos de hábitos:

DATOS HISTÓRICOS:
${_formatMapForPrompt(predictionData)}

Predice:
1. Probabilidad de mantener progreso actual
2. Hábitos con mayor riesgo de abandono
3. Estrategias preventivas específicas

Respuesta concisa en 3 líneas máximo.
''';
  }

  String _buildTrendAnalysisPrompt(Map<String, dynamic> trendData) {
    return '''
Analiza estas tendencias de hábitos:

DATOS DE TENDENCIAS:
${_formatMapForPrompt(trendData)}

Identifica:
1. Patrones estacionales o cíclicos
2. Factores que influyen en el rendimiento
3. Oportunidades de optimización

Máximo 3 líneas con insights específicos.
''';
  }

  String _buildPersonalRecommendationPrompt(Map<String, dynamic> userContext) {
    return '''
Eres un experto coach de hábitos que ayuda a usuarios de Habitiurs.

DATOS DEL USUARIO:
${_formatMapForPrompt(userContext)}

Genera un consejo personalizado y motivador:
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista
- Incluye una acción específica que puedan tomar hoy

Evita consejos genéricos, personaliza según sus datos.
''';
  }

  String _buildMotivationalPrompt(Map<String, dynamic> context) {
    return '''
Genera un mensaje motivacional personalizado basado en:

CONTEXTO:
${_formatMapForPrompt(context)}

Crea un mensaje que:
1. Reconozca su progreso actual
2. Los inspire a continuar
3. Incluya una perspectiva positiva sobre los desafíos

Máximo 2 líneas, tono alentador y específico.
''';
  }

  String _formatMapForPrompt(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  /// UTILIDADES
  Future<bool> hasInternetConnection() async {
    return await _geminiService.checkConnectivity();
  }

  void dispose() {
    _geminiService.dispose();
  }
}