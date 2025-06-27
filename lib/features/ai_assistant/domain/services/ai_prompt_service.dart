// lib/features/ai_assistant/domain/services/ai_prompt_service.dart
class AIPromptService {
  static String buildPersonalRecommendationPrompt({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required List<String> strugglingHabits,
  }) {
    final avgCompletionRate = completionRates.values.isNotEmpty 
        ? completionRates.values.reduce((a, b) => a + b) / completionRates.values.length
        : 0.0;

    return '''
Eres un experto coach de hábitos que ayuda a usuarios de una app llamada Habitiurs.

DATOS DEL USUARIO:
${habitNames.isNotEmpty ? 'Hábitos actuales: ${habitNames.join(', ')}' : 'No tiene hábitos registrados aún'}
Tasa de cumplimiento: ${(avgCompletionRate * 100).toStringAsFixed(1)}%
Racha actual: $currentStreak días
${strugglingHabits.isNotEmpty ? 'Hábitos con dificultades: ${strugglingHabits.join(', ')}' : ''}

INSTRUCCIONES:
- Analiza sus datos y da un consejo personalizado y motivador
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista

Genera tu recomendación:
''';
  }
}