import 'dart:convert';
import 'dart:io';
import 'package:habitiurs/core/ai/models/ai_request_model.dart';
import 'package:habitiurs/core/ai/models/ai_response_model.dart';
import 'package:http/http.dart' as http;

import '../prompts/habit_prompts.dart';
import '../../common/interfaces/disposable.dart';

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

/// Service for Gemini AI integration
class GeminiService with DisposableMixin {
  static const String _baseUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _apiKey = 'AIzaSyAbmPxRX-lx59wEIrgiul6jy4osediN5Ow';
  
  final http.Client _client;
  static final GeminiService _instance = GeminiService._internal();
  
  factory GeminiService() => _instance;
  GeminiService._internal() : _client = http.Client();

  /// Generate content from AI request
  Future<AIResponse> generateContent(AIRequest request) async {
    ensureNotDisposed();
    
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw AIException('API Key not configured');
    }
    
    try {
      final requestBody = {
        'contents': [{
          'parts': [{'text': request.prompt}]
        }]
      };
      
      final response = await _client.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

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
      throw AINetworkException('No internet connection');
    } on HttpException {
      throw AINetworkException('Connection error');
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException('Unexpected error: $e');
    }
  }

  /// Evaluate a habit description
  Future<AIResponse> evaluateHabit(String habitDescription) async {
    final request = AIRequest(
      type: AIRequestType.habitEvaluation,
      prompt: HabitPrompts.buildEvaluationPrompt(habitDescription),
      metadata: {'habit': habitDescription},
    );
    return await generateContent(request);
  }

  /// Check connectivity to Google services
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
        return AIException('Invalid request: $body');
      case 403:
        return AIException('Invalid API Key or no permissions');
      case 404:
        return AIException('Model not available');
      case 429:
        return AIRateLimitException('API rate limit reached');
      default:
        return AIException('API error: $statusCode');
    }
  }

  @override
  Future<void> onDispose() async {
    _client.close();
  }
}