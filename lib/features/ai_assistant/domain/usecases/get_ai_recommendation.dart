// lib/features/ai_assistant/domain/usecases/get_ai_recommendation.dart
// 🔄 REFACTORIZADO - Simplificar, delegar al repository que usa core/ai/

import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ai_assistant_repository.dart';

class GetAIRecommendation {
  final AIAssistantRepository repository;

  GetAIRecommendation(this.repository);

  Future<AIResponse> call() async {
    try {
      // ✅ Simplificado: Solo delegar al repository
      // El repository se encarga de:
      // 1. Generar contexto de usuario
      // 2. Crear AIRequest con el core
      // 3. Llamar al AIRepository centralizado
      // 4. Manejar fallbacks automáticamente
      return await repository.getAIRecommendation();
    } catch (e) {
      throw CacheFailure('Error al obtener recomendación de IA: ${e.toString()}');
    }
  }
}