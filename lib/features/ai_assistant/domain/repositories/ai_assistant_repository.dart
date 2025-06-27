// lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart
import '../../../../core/ai/models/ai_response_model.dart';
import '../entities/educational_content.dart';
import '../entities/app_guide.dart';

abstract class AIAssistantRepository {
  Future<List<EducationalContent>> getEducationalContent();
  Future<List<EducationalContent>> getOfflineEducationalContent();
  Future<List<AppGuide>> getAppGuides();
  Future<AIResponse> getAIRecommendation();
  Future<bool> hasInternetConnection();
}