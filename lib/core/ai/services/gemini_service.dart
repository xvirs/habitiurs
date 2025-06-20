// lib/core/ai/services/gemini_service.dart - ACTUALIZADO
import 'dart:convert';
import 'dart:io';
import 'package:habitiurs/core/ai/models/ai_response_model.dart';
import 'package:http/http.dart' as http;
import '../models/ai_request_model.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _apiKey = 'AIzaSyAbmPxRX-lx59wEIrgiul6jy4osediN5Ow';
  
  final http.Client _client;
  static final GeminiService _instance = GeminiService._internal();
  
  factory GeminiService() => _instance;
  GeminiService._internal() : _client = http.Client();

  /// Método principal para cualquier request de IA
  Future<AIResponse> generateContent(AIRequest request) async {
    print('🤖 [Gemini] Request type: ${request.type}');
    
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw AIException('API Key no configurada');
    }
    
    try {
      final requestBody = {
        'contents': [{
          'parts': [{
            'text': request.prompt
          }]
        }]
      };
      
      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20)); // Más tiempo para análisis complejos

      print('🤖 [Gemini] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
        
        return AIResponse(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content.trim(),
          type: request.type,
          metadata: request.metadata,
          timestamp: DateTime.now(),
          isFromAI: true,
        );
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } on SocketException {
      throw AINetworkException('Sin conexión a internet');
    } on HttpException {
      throw AINetworkException('Error de conexión');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Error inesperado: $e');
    }
  }

  /// Métodos específicos por feature (mantener compatibilidad)
  
  // HABITS
  Future<AIResponse> evaluateHabit(String habitDescription) async {
    final request = AIRequest(
      type: AIRequestType.habitEvaluation,
      prompt: _buildHabitEvaluationPrompt(habitDescription),
      metadata: {'habit': habitDescription},
    );
    return await generateContent(request);
  }

  // ✅ PROMPT BUILDERS (movidos desde AIRepository)
  String _buildHabitEvaluationPrompt(String habit) {
    return '''
Eres un experto en formación de hábitos. Evalúa este hábito propuesto:

HÁBITO: "$habit"

Evalúa según estos criterios:
1. Especificidad (¿es específico y medible?)
2. Viabilidad (¿es realista para principiantes?)
3. Claridad temporal (¿tiene frecuencia/horario claro?)
4. Motivación intrínseca (¿es personalmente significativo?)

Responde en máximo 3 líneas con:
✅ Fortalezas principales
💡 Sugerencia específica de mejora
🎯 Probabilidad de éxito: Alta/Media/Baja

Mantén un tono motivador pero realista.
''';
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await _client.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  AIException _handleHttpError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return AIException('Request inválido: $body');
      case 403:
        return AIException('API Key inválida o sin permisos');
      case 404:
        return AIException('Modelo no disponible');
      case 429:
        return AIRateLimitException('Límite de API alcanzado');
      default:
        return AIException('Error de API: $statusCode');
    }
  }

  void dispose() {
    _client.close();
  }
}

// Excepciones específicas
class AIException implements Exception {
  final String message;
  AIException(this.message);
  @override
  String toString() => 'AIException: $message';
}

class AINetworkException extends AIException {
  AINetworkException(super.message);
}

class AIRateLimitException extends AIException {
  AIRateLimitException(super.message);
}