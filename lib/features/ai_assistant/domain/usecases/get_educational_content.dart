// lib/features/ai_assistant/domain/usecases/get_educational_content.dart
import '../../../../core/errors/failures.dart';
import '../entities/educational_content.dart';
import '../repositories/ai_assistant_repository.dart';

class GetEducationalContent {
  final AIAssistantRepository repository;

  GetEducationalContent(this.repository);

  Future<List<EducationalContent>> call() async {
    try {
      final hasInternet = await repository.hasInternetConnection();
      
      if (hasInternet) {
        try {
          return await repository.getEducationalContent();
        } catch (e) {
          // Si falla la API, usar contenido offline
          return await repository.getOfflineEducationalContent();
        }
      } else {
        // Sin internet, usar contenido offline
        return await repository.getOfflineEducationalContent();
      }
    } catch (e) {
      throw CacheFailure('Error al obtener contenido educativo');
    }
  }
}

// lib/features/ai_assistant/domain/usecases/get_app_guides.dart
class GetAppGuides {
  final AIAssistantRepository repository;

  GetAppGuides(this.repository);

  Future<List<AppGuide>> call() async {
    try {
      return await repository.getAppGuides();
    } catch (e) {
      throw CacheFailure('Error al obtener guías de la app');
    }
  }
}

// lib/features/ai_assistant/domain/usecases/get_ai_recommendation.dart
class GetAIRecommendation {
  final AIAssistantRepository repository;

  GetAIRecommendation(this.repository);

  Future<AIRecommendation> call() async {
    try {
      final hasInternet = await repository.hasInternetConnection();
      
      if (hasInternet) {
        try {
          final userContext = await repository.generateUserContext();
          return await repository.getAIRecommendation(userContext);
        } catch (e) {
          // Si falla la API de Gemini, usar fallback
          final fallbacks = await repository.getFallbackRecommendations();
          return fallbacks.first;
        }
      } else {
        // Sin internet, usar fallback
        final fallbacks = await repository.getFallbackRecommendations();
        return fallbacks.first;
      }
    } catch (e) {
      throw CacheFailure('Error al obtener recomendación de IA');
    }
  }
}