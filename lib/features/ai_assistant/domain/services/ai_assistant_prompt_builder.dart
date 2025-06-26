// lib/features/ai_assistant/domain/services/ai_assistant_prompt_builder.dart
class AIAssistantPromptBuilder {
  /// Construye el prompt para obtener una recomendación personalizada para el usuario.
  ///
  /// Recibe un mapa de `context` con datos del usuario y sus hábitos.
  String buildPersonalRecommendationPrompt(Map<String, dynamic> context) {
    return '''
Eres un experto coach de hábitos que ayuda a usuarios de una app llamada Habitiurs.
DATOS DEL USUARIO:
${_formatMapForPrompt(context)}

INSTRUCCIONES:
- Analiza sus datos y da un consejo personalizado y motivador
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista

Genera tu recomendación:
''';
  }

  /// Construye un prompt para obtener conceptos de "Hábitos Atómicos"
  /// basados en los datos y estadísticas del usuario.
  ///
  /// Recibe mapas de `userContext` (hábitos) y `statisticsContext` (tasas, rachas).
  String buildAtomicHabitsConceptsPrompt({
    required Map<String, dynamic> userContext,
    required Map<String, dynamic> statisticsContext,
  }) {
    final habitNames = List<String>.from(userContext['habit_names'] ?? []);
    final strugglingHabits = List<String>.from(userContext['struggling_habits'] ?? []);
    final currentStreak = userContext['current_streak'] ?? 0;
    final totalHabits = userContext['total_habits'] ?? 0;
    
    final monthlyCompletionRate = statisticsContext['monthly_completion_rate'] as double? ?? 0.0;
    final averageWeeklyRate = statisticsContext['yearly_average_rate'] as double? ?? 0.0; // Usar yearly_average_rate para más contexto
    
    String userSummary = '';
    if (totalHabits == 0) { // Usar totalHabits para verificar si hay hábitos registrados
      userSummary = 'El usuario no tiene hábitos registrados aún.';
    } else {
      userSummary = 'Hábitos activos: ${habitNames.join(', ')}. ';
      userSummary += 'Racha actual de éxito: $currentStreak días. ';
      userSummary += 'Tasa de cumplimiento mensual: ${monthlyCompletionRate.toStringAsFixed(0)}%. ';
      userSummary += 'Tasa promedio semanal del año: ${averageWeeklyRate.toStringAsFixed(0)}%. ';
      if (strugglingHabits.isNotEmpty) {
        userSummary += 'Hábitos con dificultades: ${strugglingHabits.join(', ')}. ';
      }
    }

    return '''
Eres un asistente de IA experto en los principios de "Hábitos Atómicos" de James Clear. Tu tarea es ofrecer uno o dos conceptos clave de "Hábitos Atómicos" que sean **altamente relevantes y accionables** para el usuario, basándote en su situación actual de hábitos y estadísticas.

CONTEXTO DEL USUARIO:
$userSummary
${statisticsContext['trend_direction'] == 'improving' ? 'Tu tendencia general es de mejora.' : ''}

INSTRUCCIONES:
- Selecciona el concepto más relevante de "Hábitos Atómicos" (ej. Regla de los 2 Minutos, Hacerlo Obvio, Apilamiento de Hábitos, Hacerlo Atractivo, etc.).
- Explícalo brevemente (máximo 3 frases).
- Relaciona el concepto con el contexto específico del usuario y sugiere una acción concreta.
- Si no hay datos de usuario, o los datos son insuficientes (ej. total_habits es 0), proporciona un concepto general muy útil para empezar a construir hábitos.
- Siempre responde en un tono inspirador y pragmático.

Ejemplo de salida:
Concepto: **La Regla de los 2 Minutos**. Explicación: Cuando empieces un nuevo hábito, la clave es que la primera acción te tome menos de dos minutos. Así, te centras en "aparecer" cada día. Acción: Dada tu racha de $currentStreak días, aplica esto a tu hábito "${habitNames.isNotEmpty ? habitNames.first : 'nuevo'}" para los días que te cuesta empezar.
''';
  }


  /// Formatea un mapa de datos para ser incluido en un prompt.
  String _formatMapForPrompt(Map<String, dynamic> data) {
    final habitNames = List<String>.from(data['habit_names'] ?? []);
    final completionRates = Map<String, double>.from(data['completion_rates'] ?? {});
    final currentStreak = data['current_streak'] ?? 0;
    final strugglingHabits = List<String>.from(data['struggling_habits'] ?? []);
    final avgCompletionRate = completionRates.values.isNotEmpty 
        ? completionRates.values.reduce((a, b) => a + b) / completionRates.values.length
        : 0.0;

    return '''
${habitNames.isNotEmpty ? 'Hábitos actuales: ${habitNames.join(', ')}' : 'No tiene hábitos registrados aún'}
Tasa de cumplimiento promedio: ${(avgCompletionRate * 100).toStringAsFixed(1)}%
Racha actual: $currentStreak días
${strugglingHabits.isNotEmpty ? 'Hábitos con dificultades: ${strugglingHabits.join(', ')}' : ''}
'''.trim();
  }
}