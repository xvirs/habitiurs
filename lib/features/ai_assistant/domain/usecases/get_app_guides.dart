// lib/features/ai_assistant/domain/usecases/get_app_guides.dart
// ✅ NUEVO - UseCase específico para guías de la app

import '../../../../core/errors/failures.dart';
import '../entities/app_guide.dart';
import '../repositories/ai_assistant_repository.dart';

class GetAppGuides {
  final AIAssistantRepository repository;

  GetAppGuides(this.repository);

  Future<List<AppGuide>> call() async {
    try {
      // ✅ Simplificado: Solo obtener guías de la app
      // Es contenido local, no necesita lógica de conectividad
      return await repository.getAppGuides();
    } catch (e) {
      throw CacheFailure('Error al obtener guías de la app: ${e.toString()}');
    }
  }
}