// lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart
// 🔄 REFACTORIZADO - Eliminar lógica de IA, solo contenido específico de la feature

import '../../../../core/ai/models/ai_response_model.dart';
import '../entities/educational_content.dart';
import '../entities/app_guide.dart';

abstract class AIAssistantRepository {
  // 📚 Educational Content - Solo contenido específico de la feature
  Future<List<EducationalContent>> getEducationalContent();
  Future<List<EducationalContent>> getOfflineEducationalContent();
  
  // 📖 App Guide - Solo guías específicas de la feature
  Future<List<AppGuide>> getAppGuides();
  
  // 🤖 AI Recommendations - Delegar al core/ai/
  Future<AIResponse> getAIRecommendation();
  
  // 🌐 Connectivity - Delegar al core/ai/
  Future<bool> hasInternetConnection();
}