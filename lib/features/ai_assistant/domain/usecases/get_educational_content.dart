// lib/features/ai_assistant/domain/usecases/get_educational_content.dart
// ✅ MANTENER - UseCase específico para contenido educativo

import '../../../../core/errors/failures.dart';
import '../entities/educational_content.dart';
import '../repositories/ai_assistant_repository.dart';

class GetEducationalContent {
  final AIAssistantRepository repository;

  GetEducationalContent(this.repository);

  Future<List<EducationalContent>> call() async {
    try {
      // ✅ Simplificado: Solo obtener contenido educativo
      // No necesita lógica de conectividad porque es contenido local
      return await repository.getEducationalContent();
    } catch (e) {
      throw CacheFailure('Error al obtener contenido educativo: ${e.toString()}');
    }
  }
}