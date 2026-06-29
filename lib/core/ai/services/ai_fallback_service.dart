// lib/core/ai/services/ai_fallback_service.dart - COMPLETO
import 'package:habitiurs/core/ai/models/ai_response_model.dart';

import '../models/ai_request_model.dart';

/// Servicioque proporciona respuestas offline inteligentes
class AIFallbackService {
  Future<AIResponse> generateFallbackResponse(AIRequest request) async {
    // Simular delay para UX realista
    await Future.delayed(const Duration(milliseconds: 500));

    final content = _getFallbackContent(request.type, request.metadata);

    return AIResponse(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: request.type,
      metadata: request.metadata,
      timestamp: DateTime.now(),
      isFromAI: false, // Importante: marcar como fallback
      confidence: AIResponseConfidence(
        score: 0.6,
        level: 'medium',
        factors: ['offline_mode', 'template_based'],
      ),
    );
  }

  String _getFallbackContent(
    AIRequestType type,
    Map<String, dynamic> metadata,
  ) {
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
        return _getMotivationalMessageFallback(metadata);
      case AIRequestType.generalAdvice:
        return _getGeneralAdviceFallback(metadata);
    }
  }

  // HABITS FALLBACKS
  String _getHabitEvaluationFallback(Map<String, dynamic> metadata) {
    final habit = (metadata['habit'] as String?)?.toLowerCase().trim() ?? '';

    // Validación básica de coherencia
    if (habit.isEmpty || habit.length < 3) {
      return '❌ No válido. Demasiado corto o vacío.';
    }

    // Detectar texto sin sentido (solo consonantes repetidas, teclado random, etc.)
    final hasVowels = RegExp(
      r'[aeiouáéíóú]',
      caseSensitive: false,
    ).hasMatch(habit);
    final tooManyRepeatedChars = RegExp(r'(.)\1{3,}').hasMatch(habit);

    if (!hasVowels || tooManyRepeatedChars) {
      return '❌ No válido. No es una acción coherente.';
    }

    // Detectar metas grandiosas (no son acciones diarias repetibles)
    final grandGoals = [
      'conquistar',
      'mundo',
      'dominar',
      'universo',
      'ganar',
      'lotería',
      'rico',
      'millonario',
      'famoso',
      'estrella',
      'triunfar',
      'éxito',
    ];
    if (grandGoals.any((word) => habit.contains(word))) {
      return '❌ No válido. Es una meta grandiosa, no una acción diaria repetible.';
    }

    // Detectar estados emocionales o abstractos (no son acciones medibles)
    final emotionalStates = [
      'ser',
      'estar',
      'sentir',
      'feliz',
      'mejor',
      'bueno',
      'malo',
      'bien',
      'mal',
      'motivado',
      'positivo',
    ];
    final words = habit.split(' ');
    if (emotionalStates.any((state) => words.contains(state)) &&
        words.length <= 3) {
      return '❌ No válido. Es un estado emocional, no una acción medible.';
    }

    // Detectar cantidades no sostenibles de sueño
    if (habit.contains('dormir') &&
        (habit.contains('3') ||
            habit.contains('4') ||
            habit.contains('tres') ||
            habit.contains('cuatro'))) {
      return '❌ No válido. No es saludable ni sostenible a largo plazo.';
    }

    // Detectar acciones específicas y concretas (verbos de acción + objeto)
    final actionVerbs = [
      'leer',
      'escribir',
      'correr',
      'caminar',
      'meditar',
      'estudiar',
      'practicar',
      'beber',
      'tomar',
      'comer',
      'hacer',
      'realizar',
      'completar',
      'revisar',
      'aprender',
      'repasar',
      'ejercitar',
      'entrenar',
      'llamar',
      'contactar',
    ];

    final hasActionVerb = actionVerbs.any((verb) => habit.contains(verb));

    // Si tiene un verbo de acción y al menos 2 palabras, es probablemente válido
    if (hasActionVerb && habit.split(' ').length >= 2) {
      return '✅ Claro y viable. Listo para seguimiento diario.';
    }

    // Si es corto pero coherente
    if (habit.split(' ').length == 1) {
      return '🤔 Confuso. ¿Qué acción exacta registrarías? Sé más específico.';
    }

    // Caso genérico: parece válido pero podría mejorar
    return '💡 Funciona, pero asegúrate de que sea una acción clara y medible cada día.';
  }

  String _getHabitAnalysisFallback(Map<String, dynamic> metadata) {
    final completionRates =
        metadata['completion_rates'] as Map<String, dynamic>?;
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
    final dataPoints = metadata['data_points_count'] as int?;

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
    final currentStreak = metadata['current_streak'] as int? ?? 0;
    final habitNames = metadata['habit_names'] as List?;
    final strugglingHabits = metadata['struggling_habits'] as List?;
    final avgCompletionRate =
        metadata['average_completion_rate'] as double? ?? 0.0;

    final hasHabits = habitNames != null && habitNames.isNotEmpty;
    final hasStrugglingHabits =
        strugglingHabits != null && strugglingHabits.isNotEmpty;
    final habitCount = habitNames?.length ?? 0;

    // Caso: Sin hábitos aún
    if (!hasHabits) {
      return '**👋 Estado:** Acabas de empezar. Sin hábitos registrados aún.\n\n**💡 Acción clave:** Crea tu primer hábito HOY. Empieza con algo simple que puedas hacer en menos de 5 minutos (ej: beber agua, leer 1 página).';
    }

    // Caso: Excelente rendimiento (≥80%)
    if (performanceLevel == 'excellent' || avgCompletionRate >= 0.8) {
      final alert =
          hasStrugglingHabits
              ? '\n\n**⚠️ Alerta:** "${strugglingHabits.first}" está fallando. Revisa si es demasiado ambicioso o necesita simplificarse.'
              : '';
      return '**🔥 Estado:** Excelente constancia (${(avgCompletionRate * 100).toStringAsFixed(0)}%). ${currentStreak > 0 ? "Racha de $currentStreak días." : ""}\n\n**💡 Acción clave:** Mantén el momentum. Considera agregar UN nuevo hábito pequeño si te sientes cómodo.$alert';
    }

    // Caso: Buen rendimiento (60-79%)
    if (performanceLevel == 'good' || avgCompletionRate >= 0.6) {
      final alert =
          hasStrugglingHabits
              ? '\n\n**⚠️ Alerta:** "${strugglingHabits.first}" necesita atención. Reduce su complejidad o vinculalo con una rutina existente.'
              : '';
      return '**💪 Estado:** Buen ritmo (${(avgCompletionRate * 100).toStringAsFixed(0)}%). ${currentStreak > 0 ? "Racha: $currentStreak días." : "Sin racha activa."}\n\n**💡 Acción clave:** Identifica QUÉ días fallas más y prepara un plan B para esos días específicos.$alert';
    }

    // Caso: Rendimiento regular (40-59%)
    if (performanceLevel == 'improving' || avgCompletionRate >= 0.4) {
      final mainHabit =
          hasStrugglingHabits ? strugglingHabits.first : habitNames.first;
      return '**📈 Estado:** En desarrollo (${(avgCompletionRate * 100).toStringAsFixed(0)}%). ${currentStreak > 0 ? "Racha: $currentStreak días." : "Necesitas construir racha."}\n\n**💡 Acción clave:** Enfócate SOLO en "$mainHabit" esta semana. Ignora el resto temporalmente.\n\n**⚠️ Alerta:** Con $habitCount hábitos activos, estás dispersando tu energía. La calidad supera la cantidad.';
    }

    // Caso: Necesita atención urgente (<40%)
    if (avgCompletionRate < 0.4) {
      final mainHabit =
          hasStrugglingHabits ? strugglingHabits.first : habitNames.first;
      return '**⚡ Estado:** Necesitas reenfoque urgente (${(avgCompletionRate * 100).toStringAsFixed(0)}%). ${currentStreak > 0 ? "Racha: $currentStreak días." : "Sin racha."}\n\n**💡 Acción clave:** PAUSA todos los hábitos excepto 1. Enfócate solo en "$mainHabit" durante 7 días.\n\n**⚠️ Alerta:** Con $habitCount hábitos y baja constancia, estás sobrecargado. Simplifica radicalmente o perderás momentum.';
    }

    // Fallback final
    return '**💪 Estado:** Tienes $habitCount ${habitCount == 1 ? "hábito" : "hábitos"} activos (${(avgCompletionRate * 100).toStringAsFixed(0)}% cumplimiento).\n\n**💡 Acción clave:** Enfócate en aparecer cada día. La consistencia importa más que la perfección.';
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

  String _getGeneralAdviceFallback(Map<String, dynamic> metadata) {
    return 'Continúa enfocándote en el progreso constante. Pequeños pasos diarios construyen grandes transformaciones a largo plazo. Celebra cada victoria, por pequeña que sea.';
  }
}
