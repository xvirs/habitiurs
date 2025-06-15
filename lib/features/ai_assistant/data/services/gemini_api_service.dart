// lib/features/ai_assistant/data/services/gemini_api_service.dart - GEMINI 2.0 FLASH
import 'dart:convert';
import 'dart:io';
import 'package:habitiurs/features/ai_assistant/domain/entities/educational_content.dart';
import 'package:http/http.dart' as http;

class GeminiApiService {
  // ACTUALIZADO: Usar gemini-2.0-flash (el más nuevo)
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _apiKey = 'AIzaSyAbmPxRX-lx59wEIrgiul6jy4osediN5Ow';
  
  final http.Client _client;

  GeminiApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<AIRecommendation> getRecommendation(UserContext context) async {
    print('🔍 [Gemini] Iniciando petición...');
    print('🔍 [Gemini] API Key configurada: ${_apiKey != "YOUR_GEMINI_API_KEY_HERE"}');
    print('🔍 [Gemini] Modelo: gemini-2.0-flash');
    
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      print('❌ [Gemini] API Key no configurada');
      throw ApiException('API Key no configurada');
    }
    
    try {
      final prompt = _buildPrompt(context);
      print('🔍 [Gemini] Prompt generado: ${prompt.substring(0, 100)}...');
      
      // SIMPLIFICADO: Estructura igual a la de Google
      final requestBody = {
        'contents': [{
          'parts': [{
            'text': prompt
          }]
        }]
      };
      
      print('🔍 [Gemini] Enviando petición a: $_baseUrl');
      
      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      print('🔍 [Gemini] Status Code: ${response.statusCode}');
      print('🔍 [Gemini] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Verificar estructura de respuesta
        if (data['candidates'] == null || 
            data['candidates'].isEmpty ||
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty) {
          print('❌ [Gemini] Estructura de respuesta inválida');
          print('❌ [Gemini] Data recibida: $data');
          throw ApiException('Respuesta inválida de la API');
        }
        
        final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
        print('✅ [Gemini] Recomendación recibida: ${content.substring(0, 50)}...');
        
        return AIRecommendation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: content.trim(),
          timestamp: DateTime.now(),
          type: _determineRecommendationType(context),
          isFromAI: true,
          context: context.toJson(),
        );
      } else if (response.statusCode == 400) {
        print('❌ [Gemini] Error 400 - Request inválido: ${response.body}');
        throw ApiException('Request inválido: ${response.body}');
      } else if (response.statusCode == 403) {
        print('❌ [Gemini] Error 403 - API Key inválida o sin permisos');
        throw ApiException('API Key inválida o sin permisos');
      } else if (response.statusCode == 404) {
        print('❌ [Gemini] Error 404 - Modelo no encontrado: ${response.body}');
        throw ApiException('Modelo no disponible');
      } else if (response.statusCode == 429) {
        print('❌ [Gemini] Error 429 - Rate limit excedido');
        throw RateLimitException('Límite de API alcanzado');
      } else {
        print('❌ [Gemini] Error ${response.statusCode}: ${response.body}');
        throw ApiException('Error de API: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('❌ [Gemini] Sin conexión: $e');
      throw NetworkException('Sin conexión a internet');
    } on HttpException catch (e) {
      print('❌ [Gemini] Error HTTP: $e');
      throw NetworkException('Error de conexión');
    } catch (e) {
      print('❌ [Gemini] Error inesperado: $e');
      if (e is RateLimitException || e is NetworkException || e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  String _buildPrompt(UserContext context) {
    final prompt = '''
Eres un experto coach de hábitos que ayuda a usuarios de una app llamada Habitiurs.

DATOS DEL USUARIO:
${context.habitNames.isNotEmpty ? 'Hábitos actuales: ${context.habitNames.join(', ')}' : 'No tiene hábitos registrados aún'}
Tasa de cumplimiento: ${context.completionRates.values.isNotEmpty ? (context.completionRates.values.reduce((a, b) => a + b) / context.completionRates.values.length * 100).toStringAsFixed(1) : '0'}%
Racha actual: ${context.currentStreak} días
${context.strugglingHabits.isNotEmpty ? 'Hábitos con dificultades: ${context.strugglingHabits.join(', ')}' : ''}

INSTRUCCIONES:
- Analiza sus datos y da un consejo personalizado y motivador
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista

Genera tu recomendación:
''';

    return prompt;
  }

  RecommendationType _determineRecommendationType(UserContext context) {
    if (context.currentStreak == 0) return RecommendationType.recovery;
    if (context.currentStreak >= 7) return RecommendationType.streak;
    if (context.strugglingHabits.isNotEmpty) return RecommendationType.improvement;
    
    final avgCompletionRate = context.completionRates.values.isNotEmpty 
        ? context.completionRates.values.reduce((a, b) => a + b) / context.completionRates.values.length
        : 0.0;
    
    if (avgCompletionRate < 0.5) return RecommendationType.motivation;
    return RecommendationType.general;
  }

  Future<bool> checkConnectivity() async {
    try {
      print('🔍 [Connectivity] Verificando conexión...');
      final response = await _client.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      
      final hasConnection = response.statusCode == 200;
      print('🔍 [Connectivity] Resultado: $hasConnection');
      return hasConnection;
    } catch (e) {
      print('❌ [Connectivity] Error: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

// Excepciones personalizadas
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}