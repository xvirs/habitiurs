// lib/core/ai/services/ai_fallback_service.dart
import 'package:habitiurs/core/ai/models/ai_response_model.dart';

import '../models/ai_request_model.dart';

class AIFallbackService {
  // Constructor privado para el patrón Singleton.
  AIFallbackService._internal();

  // Única instancia de la clase (Singleton).
  static final AIFallbackService _instance = AIFallbackService._internal();

  // Factory constructor para devolver siempre la misma instancia.
  factory AIFallbackService() {
    return _instance;
  }
  
  Future<AIResponse> generateFallbackResponse(AIRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final content = _getFallbackContent(request.type, request.metadata);
    
    return AIResponse(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: request.type,
      metadata: request.metadata,
      timestamp: DateTime.now(),
      isFromAI: false,
      confidence: const AIResponseConfidence(
        score: 0.6,
        level: 'medium',
        factors: ['offline_mode', 'template_based'],
      ),
    );
  }

  // Métodos públicos para obtener contenido de fallback específico directamente (para UI).
  // Estos son de instancia, por lo que se llamarán en una instancia de AIFallbackService.
  String getPersonalRecommendationFallbackContent(Map<String, dynamic> metadata) {
    return _getPersonalRecommendationFallback(metadata);
  }

  String getAtomicHabitsConceptsFallbackContent(Map<String, dynamic> metadata) {
    return _getAtomicHabitsConceptsFallback(metadata);
  }


  String _getFallbackContent(AIRequestType type, Map<String, dynamic> metadata) {
    switch (type) {
      case AIRequestType.habitEvaluation:
        return _getHabitEvaluationFallback(metadata);
      case AIRequestType.habitAnalysis:
        return _getHabitAnalysisFallback(metadata);
      case AIRequestType.habitSuggestion:
        return _getHabitSuggestionFallback(metadata);
      case AIRequestType.statisticsAnalysis:
        return _getStatsAnalysisFallback(metadata);
      case AIRequestType.successPrediction:
        return _getPredictionFallback(metadata);
      case AIRequestType.trendAnalysis:
        return _getTrendAnalysisFallback(metadata);
      case AIRequestType.personalRecommendation:
        return _getPersonalRecommendationFallback(metadata);
      case AIRequestType.motivationalMessage: 
        return _getAtomicHabitsConceptsFallback(metadata); 
      case AIRequestType.generalAdvice:
        return _getGeneralAdviceFallback(metadata);
    }
  }

  // HABITS FALLBACKS
  String _getHabitEvaluationFallback(Map<String, dynamic> metadata) {
    final fallbacks = [
      '✅ Hábito bien estructurado y específico.\n💡 Considera añadir un horario específico para mayor consistencia.\n🎯 Probabilidad de éxito: Alta',
      '✅ Objetivo claro y medible.\n💡 Prueba vincularlo con una rutina existente para facilitar la adopción.\n🎯 Probabilidad de éxito: Media-Alta',
      '✅ Enfoque realista y sostenible.\n💡 Reduce la complejidad inicial si es necesario.\n🎯 Probabilidad de éxito: Media',
      '✅ Buena intención y claridad.\n💡 Asegúrate de que sea específico y medible.\n🎯 Probabilidad de éxito: Media',
      '✅ Hábito alcanzable y práctico.\n💡 Define cuándo y dónde lo realizarás exactamente.\n🎯 Probabilidad de éxito: Alta',
    ];
    return fallbacks[DateTime.now().millisecond % fallbacks.length];
  }

  String _getHabitAnalysisFallback(Map<String, dynamic> metadata) {
    final strugglingHabits = metadata['struggling_habits'] as List<dynamic>?;
    
    if (strugglingHabits?.isNotEmpty == true) {
      return 'Basándome en tus patrones, los hábitos "${strugglingHabits!.join(', ')}" necesitan atención extra. Te sugiero reducir su complejidad y establecer recordatorios específicos. Enfócate en consistencia antes que en perfección.';
    } else {
      return 'Basándome en tus patrones, tu consistencia mejora con rutinas matutinas. Te sugiero concentrarte en 2-3 hábitos clave y establecer recordatorios específicos para los días más desafiantes.';
    }
  }

  String _getHabitSuggestionFallback(Map<String, dynamic> metadata) {
    final suggestions = [
      'Para mejorar tu consistencia, prueba: 1) Reduce el tiempo inicial de cada hábito, 2) Agrupa hábitos similares en la misma sesión, 3) Establece un recordatorio visual en tu entorno.',
      'Estrategias para el éxito: 1) Usa la regla de 2 minutos para empezar, 2) Vincula hábitos nuevos con rutinas existentes, 3) Celebra pequeños progresos para mantener motivación.',
      'Recomendaciones personalizadas: 1) Identifica tu horario de mayor energía, 2) Prepara tu entorno la noche anterior, 3) Ten un plan B para días difíciles.',
    ];
    return suggestions[DateTime.now().second % suggestions.length];
  }

  // STATISTICS FALLBACKS
  String _getStatsAnalysisFallback(Map<String, dynamic> metadata) {
    final monthlyRate = metadata['monthly_completion_rate'] as double?;
    if (monthlyRate != null) {
      if (monthlyRate >= 70) {
        return 'Tu progreso muestra una excelente tendencia con ${monthlyRate.toInt()}% de constancia. Las semanas de mayor éxito coinciden con rutinas estructuradas. Mantén este momentum y considera agregar gradualmente nuevos desafíos.';
      } else if (monthlyRate >= 50) {
        return 'Tu progreso del ${monthlyRate.toInt()}% es sólido y muestra potencial de mejora. Identifica qué factores contribuyen a tus días exitosos y trata de replicar esas condiciones más frecuentemente.';
      } else {
        return 'Con ${monthlyRate.toInt()}% de constancia, hay oportunidad de crecimiento. Enfócate en simplificar tus hábitos y establecer rutinas más pequeñas pero consistentes. El progreso incremental es clave.';
      }
    }
    
    return 'Tu progreso muestra una tendencia positiva. Las semanas con mayor éxito coinciden con rutinas más estructuradas. Enfócate en replicar esas condiciones exitosas y mantén expectativas realistas.';
  }

  String _getPredictionFallback(Map<String, dynamic> metadata) {
    final currentTrend = metadata['current_trend'] as double?;
    
    if (currentTrend != null && currentTrend > 0) {
      return 'Con tu tendencia actual positiva (+${currentTrend.toStringAsFixed(1)}%), tienes buenas probabilidades de mantener el progreso. Continúa con tu rutina actual y ajusta gradualmente si es necesario.';
    } else if (currentTrend != null && currentTrend < 0) {
      return 'Tu tendencia muestra una leve disminución (${currentTrend.toStringAsFixed(1)}%). Es normal tener fluctuaciones. Revisa qué cambió en tu rutina y considera simplificar temporalmente tus hábitos.';
    }
    
    return 'Con tu tendencia actual, tienes buenas probabilidades de mantener el progreso. Los hábitos más nuevos necesitan atención extra. Considera ajustar metas si la constancia baja del 60%.';
  }

  String _getTrendAnalysisFallback(Map<String, dynamic> metadata) {
    final trendDirection = metadata['trend_direction'] as String?;
    if (trendDirection == 'improving') {
      return 'Tu patrón muestra una mejora consistente a lo largo del tiempo. Los factores clave incluyen rutinas matutinas y preparación previa. Mantén estos elementos y escala gradualmente.';
    } else if (trendDirection == 'declining') {
      return 'Tu patrón muestra algunos desafíos recientes. Los fines de semana y cambios de rutina son puntos débiles comunes. Prepara estrategias específicas para estos momentos vulnerables.';
    }
    
    return 'Tu patrón de constancia muestra mejora gradual. Los fines de semana son tu punto más débil. Te sugiero preparar estrategias específicas para mantener momentum durante esos días.';
  }

  // AI ASSISTANT FALLBACKS
  String _getPersonalRecommendationFallback(Map<String, dynamic> metadata) {
    final performanceLevel = metadata['performance_level'] as String?;
    final currentStreak = metadata['current_streak'] as int?;

    if (performanceLevel == 'excellent') {
      return '¡Excelente trabajo! Tu consistencia es admirable. Incluso sin conexión, mantén tu ritmo. Celebra tus logros y busca nuevas formas de integrar tus hábitos.';
    } else if (performanceLevel == 'good') {
      return 'Vas por buen camino. Tu progreso es sólido y constante. Si estás offline, enfócate en optimizar tu rutina matutina y prepara estrategias para días desafiantes. La persistencia es clave.';
    } else if (currentStreak != null && currentStreak > 0) {
      return 'Tu racha de ${currentStreak} días muestra compromiso real. Los hábitos se están consolidando. Mantén la simplicidad y enfócate en aparecer todos los días, incluso en versiones mínimas. ¡Sigue así!';
    }
    
    final fallbacks = [
      'Recuerda que los hábitos pequeños y consistentes superan a los grandes y esporádicos. Si has fallado algunos días, simplemente vuelve a empezar mañana. Lo importante es la tendencia general, no la perfección absoluta.',
      'Identifica qué está funcionando bien en tus hábitos actuales y trata de aplicar esas mismas estrategias a los hábitos que te cuestan más trabajo. A menudo, el éxito en un área puede transferirse a otras.',
      'Considera revisar tus hábitos actuales. ¿Siguen siendo relevantes para tus objetivos? A veces es mejor enfocarse en 2-3 hábitos importantes que intentar mantener muchos a medias. La calidad supera a la cantidad.',
      'Incluso sin conexión, cada pequeño paso cuenta. No te desanimes por los contratiempos, son parte del camino. ¡Vuelve a tus hábitos hoy mismo!',
      'Usa este tiempo para reflexionar sobre tus "porqués". ¿Por qué quieres construir estos hábitos? Reconectar con tu propósito es una estrategia poderosa para la constancia. ¡Puedes hacerlo!',
    ];
    return fallbacks[DateTime.now().second % fallbacks.length];
  }

  String _getMotivationalMessageFallback(Map<String, dynamic> metadata) {
    final encouragementType = metadata['encouragement_type'] as String?;
    switch (encouragementType) {
      case 'celebration':
        return '¡Increíble progreso! Tu dedicación está dando frutos. Cada día que apareces estás construyendo una versión más fuerte de ti mismo. ¡Sigue brillando!';
      case 'recovery':
        return 'Los altibajos son parte del proceso. Lo importante no es nunca fallar, sino qué tan rápido te levantas. Hoy es una nueva oportunidad para volver a empezar.';
      case 'motivation':
        return 'Cada pequeño paso cuenta. No subestimes el poder de acciones simples y constantes. Estás más cerca de tus objetivos de lo que crees.';
      default:
        return '¡Cada día que apareces estás construyendo la versión más fuerte de ti mismo! El progreso no siempre es lineal, pero tu compromiso constante es lo que marca la diferencia real.';
    }
  }

  String _getAtomicHabitsConceptsFallback(Map<String, dynamic> metadata) {
    final userMood = metadata['user_mood'] as String? ?? 'neutral';
    final currentStreak = metadata['current_streak'] as int? ?? 0;
    final weeklyProgress = metadata['weekly_progress'] as double? ?? 0.0;

    List<String> concepts = [
      "Concepto: **La Regla de los 2 Minutos**. Explicación: Cuando empieces un nuevo hábito, la clave es que la primera acción te tome menos de dos minutos. Así, te centras en 'aparecer' cada día. Acción: Reduce uno de tus hábitos a un inicio de dos minutos hoy.",
      "Concepto: **Hacerlo Obvio**. Explicación: Las señales de tu entorno son poderosas. Haz que tus buenos hábitos sean visibles. Acción: Coloca lo necesario para tu próximo hábito en un lugar que veas constantemente.",
      "Concepto: **Apilamiento de Hábitos**. Explicación: Conecta un nuevo hábito con uno que ya tienes. Esto crea un 'gatillo' natural. Acción: Después de [hábito existente], haré [nuevo hábito].",
      "Concepto: **Hacerlo Atractivo**. Explicación: Cuanto más atractivo es un hábito, más fácil es que lo hagas. Acción: Empareja el hábito que te cuesta con algo que disfrutes hacer.",
      "Concepto: **Hacerlo Fácil**. Explicación: Reduce la fricción. La energía necesaria para empezar es el mayor obstáculo. Acción: Elimina un obstáculo que te impida iniciar tu hábito.",
    ];

    if (currentStreak > 7 && weeklyProgress > 0.8) {
      return "¡Excelente racha! Concepto: **El principio del Mínimo Esfuerzo**. Explicación: La energía que se necesita para empezar un hábito es clave. Cuanto más fácil, mejor. Acción: Piensa en cómo puedes simplificar aún más tu hábito más consolidado para mantenerlo sin esfuerzo.";
    } else if (currentStreak == 0 || userMood == 'struggling') {
      return "Ánimo, es normal tener días difíciles. Concepto: **La Regla de los 2 Minutos**. Explicación: Cuando estés comenzando o reiniciando un hábito, la clave es que la primera acción te tome menos de dos minutos. Así, te centras en 'aparecer' cada día sin presión. Acción: Hoy, solo haz una versión de dos minutos de un hábito que te esté costando.";
    } else if (weeklyProgress < 0.5) {
      return "Estás progresando. Concepto: **Hacerlo Obvio**. Explicación: Las señales visuales en tu entorno son poderosas. Haz que el camino hacia tu hábito sea inevitable. Acción: Organiza tu espacio para que la próxima vez que intentes hacer un hábito, los materiales estén listos y a la vista.";
    }

    return concepts[DateTime.now().second % concepts.length];
  }

  String _getGeneralAdviceFallback(Map<String, dynamic> metadata) {
    return 'Continúa enfocándote en el progreso constante. Pequeños pasos diarios construyen grandes transformaciones a largo plazo. Celebra cada victoria, por pequeña que sea.';
  }
}