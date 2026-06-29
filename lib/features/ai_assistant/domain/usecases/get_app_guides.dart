// lib/features/ai_assistant/domain/usecases/get_app_guides.dart
import '../../../../core/errors/failures.dart';
import '../entities/app_guide.dart';
import '../repositories/ai_assistant_repository.dart';

class GetAppGuides {
  final AIAssistantRepository repository;

  GetAppGuides(this.repository);

  Future<List<AppGuide>> call() async {
    try {
      return await repository.getAppGuides();
    } catch (e) {
      throw CacheFailure('Error al obtener guías de la app: ${e.toString()}');
    }
  }
}
