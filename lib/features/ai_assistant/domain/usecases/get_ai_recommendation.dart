import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ai_assistant_repository.dart';

class GetAIRecommendation {
  final AIAssistantRepository repository;

  GetAIRecommendation(this.repository);

  Future<AIResponse> call() async {
    try {
      return await repository.getAIRecommendation();
    } catch (e) {
      throw CacheFailure('Error al obtener recomendación de IA: ${e.toString()}');
    }
  }
}
