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
Eres un experto en el seguimiento y la asistencia de hábitos mediante IA. Tu enfoque es ayudar al usuario a formular hábitos que sean fáciles de **trakear** y mantener diariamente, **sin que la aplicación se convierta en una herramienta de gestión de tareas o horarios**. Evalúa el siguiente hábito propuesto.

HÁBITO: "$habit"

Criterios de Evaluación:
1.  **Claridad:** ¿Es el hábito fácil de entender y recordar para marcar su cumplimiento diario?
2.  **Viabilidad:** ¿Es realista y alcanzable para una persona común, facilitando el seguimiento constante?
3.  **Simplicidad:** ¿El hábito es conciso y directo, sin detalles excesivos o que requieran planificación de tiempo específica?
4.  **Enfoque en el Tracking:** ¿El hábito es adecuado para un seguimiento binario (hecho/no hecho) sin complicaciones?

Instrucciones para la Respuesta:
* **Formato de Salida:** Responde siempre en **exactamente 2 líneas cortas y concisas**.
* **Contenido:**
    * **Línea 1:**
        * Si el hábito es excelente bajo los criterios, coloca: "Es un excelente hábito para trackear." 
        * Si hay una fortaleza clave o una sugerencia breve y muy útil (que mejore significativamente la efectividad o conveniencia para el tracking), usa "✅" o "💡". **No es obligatorio dar una sugerencia o fortaleza si no hay algo realmente valioso que aportar.**
        * Prioriza una sola idea por línea. Evita cualquier mención de horarios o planificación.
    * **Línea 2:** Siempre incluye la "🎯 Probabilidad de éxito: [Alta/Media/Baja]". Esta línea debe ser la última y no debe contener otra información.
* **Tono:** Sé directo, objetivo y realista. Solo proporciona insights si suman a la claridad y facilidad de seguimiento diario.

Ejemplos de Formato de Salida (adaptado según necesidad):
-   Es un excelente hábito para trackear.
-   🎯 Probabilidad de éxito: Alta.

-   ✅ Muy claro y viable para el seguimiento.
-   🎯 Probabilidad de éxito: Alta.

-   💡 Simplifica la acción para facilitar el marcado diario.
-   🎯 Probabilidad de éxito: Media.

-   Necesita ser más conciso para el tracking.
-   🎯 Probabilidad de éxito: Baja.
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