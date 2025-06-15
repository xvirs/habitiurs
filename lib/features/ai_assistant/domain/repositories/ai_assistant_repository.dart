// lib/features/ai_assistant/domain/repositories/ai_assistant_repository.dart
import '../entities/educational_content.dart';

abstract class AIAssistantRepository {
  // Educational Content
  Future<List<EducationalContent>> getEducationalContent();
  Future<List<EducationalContent>> getOfflineEducationalContent();
  
  // App Guide
  Future<List<AppGuide>> getAppGuides();
  
  // AI Recommendations
  Future<AIRecommendation> getAIRecommendation(UserContext context);
  Future<List<AIRecommendation>> getFallbackRecommendations();
  Future<UserContext> generateUserContext();
  
  // Connectivity
  Future<bool> hasInternetConnection();
}