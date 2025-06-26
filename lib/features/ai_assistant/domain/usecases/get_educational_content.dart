import '../../../../core/errors/failures.dart';
import '../entities/educational_content.dart';
import '../repositories/ai_assistant_repository.dart';

class GetEducationalContent {
  final AIAssistantRepository repository;

  GetEducationalContent(this.repository);

  Future<List<EducationalContent>> call() async {
    try {
      return await repository.getEducationalContent();
    } catch (e) {
      throw CacheFailure('Error al obtener contenido educativo: ${e.toString()}');
    }
  }
}
