import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:habitiurs/core/ai/models/ai_response_model.dart';
import 'package:http/http.dart' as http;
import '../models/ai_request_model.dart';

class GeminiService {
  // gemini-2.0-flash fue apagado el 2026-06-01; usamos el modelo vigente.
  static const String _modelName = 'gemini-2.5-flash';

  // El modelo se crea de forma perezosa porque FirebaseAI requiere que
  // Firebase.initializeApp() ya se haya ejecutado.
  GenerativeModel? _model;

  GenerativeModel get _generativeModel {
    return _model ??= FirebaseAI.googleAI().generativeModel(model: _modelName);
  }

  final http.Client _client;
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() => _instance;
  GeminiService._internal() : _client = http.Client();

  Future<AIResponse> generateContent(AIRequest request) async {
    try {
      final response = await _generativeModel
          .generateContent([Content.text(request.prompt)])
          .timeout(const Duration(seconds: 20));

      final content = response.text;
      if (content == null || content.isEmpty) {
        throw AIException('Respuesta vacía del modelo');
      }

      return AIResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content.trim(),
        type: request.type,
        metadata: request.metadata,
        timestamp: DateTime.now(),
        isFromAI: true,
      );
    } on FirebaseAIException catch (e) {
      throw _mapFirebaseAIError(e);
    } on SocketException {
      throw AINetworkException('Sin conexión a internet');
    } on HttpException {
      throw AINetworkException('Error de conexión');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Error inesperado: $e');
    }
  }

  Future<AIResponse> evaluateHabit(String prompt) async {
    final request = AIRequest(
      type: AIRequestType.habitEvaluation,
      prompt: prompt,
      metadata: {},
    );
    return await generateContent(request);
  }

  Future<bool> checkConnectivity() async {
    try {
      final response = await _client
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  AIException _mapFirebaseAIError(FirebaseAIException e) {
    final message = e.message.toLowerCase();
    if (message.contains('quota') ||
        message.contains('resource exhausted') ||
        message.contains('429')) {
      return AIRateLimitException('Límite de API alcanzado');
    }
    if (message.contains('permission') ||
        message.contains('app check') ||
        message.contains('forbidden')) {
      return AIException('Acceso denegado al servicio de IA');
    }
    if (message.contains('not found')) {
      return AIException('Modelo no disponible');
    }
    return AIException('Error de API: ${e.message}');
  }

  void dispose() {
    _client.close();
  }
}

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
