// lib/features/ai_assistant/domain/services/ai_prompt_service.dart
class AIPromptService {
  static String buildPersonalRecommendationPrompt({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required List<String> strugglingHabits,
  }) {
    final avgCompletionRate =
        completionRates.values.isNotEmpty
            ? completionRates.values.reduce((a, b) => a + b) /
                completionRates.values.length
            : 0.0;

    return '''
Eres un coach DIRECTO y HONESTO para Habitiurs (app de seguimiento de hábitos diarios).

DATOS DEL USUARIO:
${habitNames.isNotEmpty ? '• Hábitos: ${habitNames.join(', ')}' : '• Sin hábitos aún'}
• Cumplimiento promedio: ${(avgCompletionRate * 100).toStringAsFixed(0)}%
• Racha actual: $currentStreak días
${strugglingHabits.isNotEmpty ? '• Con dificultades: ${strugglingHabits.join(', ')}' : '• Sin hábitos problemáticos'}

TU TAREA: Dar una recomendación CONCISA y ACCIONABLE usando este formato:

**[EMOJI] Estado:** [1 frase sobre su situación actual - sé honesto]

**💡 Acción clave:** [1 cosa específica que puede hacer HOY para mejorar]

${strugglingHabits.isNotEmpty ? '**⚠️ Alerta:** [Menciona brevemente el hábito problemático y por qué falla]' : ''}

REGLAS:
- Máximo 3 líneas por sección
- Usa emojis: 📈 mejorando, 🔥 excelente, ⚡ necesita acción, 💪 buen camino
- Sé directo, sin rodeos motivacionales vacíos
- Si va mal, dilo. Si va bien, celébralo brevemente

Genera tu recomendación:
''';
  }
}
