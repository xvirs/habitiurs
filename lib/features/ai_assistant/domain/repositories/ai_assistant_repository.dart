import '../../../../core/ai/models/ai_response_model.dart';
import '../entities/educational_content.dart';
import '../entities/app_guide.dart';

abstract class AIAssistantRepository {
  Future<List<EducationalContent>> getEducationalContent();
  Future<List<EducationalContent>> getOfflineEducationalContent();
  
  Future<List<AppGuide>> getAppGuides();
  
  Future<AIResponse> getAIRecommendation();

  Future<AIResponse> getAtomicHabitsConcepts({
    required Map<String, dynamic> userContext,
    required Map<String, dynamic> statisticsContext,
  });
  
  Future<bool> hasInternetConnection();
}
