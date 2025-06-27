import 'package:habitiurs/core/ai/models/ai_request_model.dart';
import 'package:habitiurs/core/ai/models/ai_response_model.dart';

/// Service for offline AI responses
class AIFallbackService {
  static const Duration _simulatedDelay = Duration(milliseconds: 500);
  
  Future<AIResponse> generateFallbackResponse(AIRequest request) async {
    await Future.delayed(_simulatedDelay);
    
    final content = _getFallbackContent(request.type, request.metadata);
    
    return AIResponse.fallback(
      content: content,
      type: request.type,
      metadata: request.metadata,
    );
  }

  String _getFallbackContent(AIRequestType type, Map<String, dynamic> metadata) {
    return switch (type) {
      AIRequestType.habitEvaluation => _getHabitEvaluationFallback(),
      AIRequestType.habitAnalysis => _getHabitAnalysisFallback(metadata),
      AIRequestType.statisticsAnalysis => _getStatsAnalysisFallback(metadata),
      AIRequestType.personalRecommendation => _getPersonalRecommendationFallback(metadata),
      AIRequestType.motivationalMessage => _getMotivationalMessageFallback(metadata),
      _ => _getGeneralAdviceFallback(),
    };
  }

  String _getHabitEvaluationFallback() {
    final fallbacks = [
      '✅ Hábito bien estructurado y específico.\n🎯 Probabilidad de éxito: Alta',
      '💡 Considera añadir un horario específico para mayor consistencia.\n🎯 Probabilidad de éxito: Media-Alta',
      '✅ Enfoque realista y sostenible.\n🎯 Probabilidad de éxito: Media',
      '💡 Asegúrate de que sea específico y medible.\n🎯 Probabilidad de éxito: Media',
      '✅ Hábito alcanzable y práctico.\n🎯 Probabilidad de éxito: Alta',
    ];
    return fallbacks[DateTime.now().millisecond % fallbacks.length];
  }

  String _getHabitAnalysisFallback(Map<String, dynamic> metadata) {
    final strugglingHabits = metadata['struggling_habits'] as List<dynamic>?;
    
    if (strugglingHabits?.isNotEmpty == true) {
      return 'Los hábitos "${strugglingHabits!.join(', ')}" necesitan atención extra. '
             'Te sugiero reducir su complejidad y establecer recordatorios específicos.';
    }
    
    return 'Tu consistencia mejora con rutinas matutinas. Concéntrate en 2-3 hábitos clave '
           'y establece recordatorios específicos para los días más desafiantes.';
  }

  String _getStatsAnalysisFallback(Map<String, dynamic> metadata) {
    final monthlyRate = metadata['monthly_completion_rate'] as double?;
    
    if (monthlyRate != null) {
      if (monthlyRate >= 70) {
        return 'Excelente progreso con ${monthlyRate.toInt()}% de constancia. '
               'Mantén este momentum y considera agregar gradualmente nuevos desafíos.';
      } else if (monthlyRate >= 50) {
        return 'Tu progreso del ${monthlyRate.toInt()}% es sólido. '
               'Identifica qué factores contribuyen a tus días exitosos.';
      } else {
        return 'Con ${monthlyRate.toInt()}% de constancia, enfócate en simplificar '
               'tus hábitos y establecer rutinas más pequeñas pero consistentes.';
      }
    }
    
    return 'Tu progreso muestra una tendencia positiva. Enfócate en replicar '
           'las condiciones exitosas y mantén expectativas realistas.';
  }

  String _getPersonalRecommendationFallback(Map<String, dynamic> metadata) {
    final performanceLevel = metadata['performance_level'] as String?;
    final currentStreak = metadata['current_streak'] as int?;
    
    if (performanceLevel == 'excellent') {
      return '¡Excelente trabajo! Para mantener este nivel, considera variar '
             'ocasionalmente tus rutinas para evitar monotonía.';
    } else if (performanceLevel == 'good') {
      return 'Vas por buen camino. Para el siguiente nivel, enfócate en optimizar '
             'tu rutina matutina y prepara estrategias para días desafiantes.';
    } else if (currentStreak != null && currentStreak > 0) {
      return 'Tu racha de $currentStreak días muestra compromiso real. '
             'Mantén la simplicidad y enfócate en aparecer todos los días.';
    }
    
    return 'Los hábitos pequeños y consistentes superan a los grandes y esporádicos. '
           'Lo importante es la tendencia general, no la perfección absoluta.';
  }

  String _getMotivationalMessageFallback(Map<String, dynamic> metadata) {
    final encouragementType = metadata['encouragement_type'] as String?;
    
    return switch (encouragementType) {
      'celebration' => '¡Increíble progreso! Cada día que apareces estás construyendo '
                      'una versión más fuerte de ti mismo. ¡Sigue brillando!',
      'recovery' => 'Los altibajos son parte del proceso. Hoy es una nueva '
                   'oportunidad para volver a empezar.',
      'motivation' => 'Cada pequeño paso cuenta. Estás más cerca de tus objetivos '
                     'de lo que crees.',
      _ => '¡Cada día que apareces estás construyendo la versión más fuerte de ti mismo! '
          'Tu compromiso constante es lo que marca la diferencia real.',
    };
  }

  String _getGeneralAdviceFallback() =>
      'Continúa enfocándote en el progreso constante. Pequeños pasos diarios '
      'construyen grandes transformaciones a largo plazo.';
}