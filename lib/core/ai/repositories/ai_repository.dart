
import 'package:habitiurs/core/ai/models/ai_request_model.dart';
import 'package:habitiurs/core/ai/models/ai_response_model.dart';

import '../services/gemini_service.dart';
import '../services/ai_fallback_service.dart';
import '../../common/interfaces/disposable.dart';

  /// Central repository for AI functionality
class AIRepository with DisposableMixin {
  final GeminiService _geminiService;
  final AIFallbackService _fallbackService;
  
  static final AIRepository _instance = AIRepository._internal();
  factory AIRepository() => _instance;
  
  AIRepository._internal() 
      : _geminiService = GeminiService(),
        _fallbackService = AIFallbackService();

  /// Generate AI response with automatic fallback
  Future<AIResponseConfidence> generateResponse(AIRequest request) async {
    ensureNotDisposed();
    
    try {
      final hasConnection = await _geminiService.checkConnectivity();
      
      if (hasConnection) {
        return await _geminiService.generateContent(request);
      } else {
        return await _fallbackService.generateFallbackResponse(request);
      }
    } catch (e) {
      return await _fallbackService.generateFallbackResponse(request);
    }
  }

  /// Evaluate a habit description
  Future<AIResponse> evaluateHabit(String habitDescription) async {
    ensureNotDisposed();
    return await _geminiService.evaluateHabit(habitDescription);
  }

  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    ensureNotDisposed();
    return await _geminiService.checkConnectivity();
  }

  @override
  Future<void> onDispose() async {
    await _geminiService.dispose();
  }
}