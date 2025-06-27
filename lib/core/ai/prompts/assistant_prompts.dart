class AssistantPrompts {
  static String buildPersonalRecommendationPrompt(Map<String, dynamic> userContext) => '''
Eres un experto coach de hábitos que ayuda a usuarios de Habitiurs.

DATOS DEL USUARIO:
${_formatDataForPrompt(userContext)}

Genera un consejo personalizado y motivador:
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista
- Incluye una acción específica que puedan tomar hoy

Evita consejos genéricos, personaliza según sus datos.
''';

  static String buildMotivationalPrompt(Map<String, dynamic> context) => '''
Genera un mensaje motivacional personalizado basado en:

CONTEXTO:
${_formatDataForPrompt(context)}

Crea un mensaje que:
1. Reconozca su progreso actual
2. Los inspire a continuar
3. Incluya una perspectiva positiva sobre los desafíos

Máximo 2 líneas, tono alentador y específico.
''';

  static String buildGeneralAdvicePrompt(Map<String, dynamic> context) => '''
Proporciona un consejo general sobre formación de hábitos basado en:

CONTEXTO:
${_formatDataForPrompt(context)}

Enfócate en principios fundamentales de construcción de hábitos.
Máximo 3 líneas, aplicable universalmente.
''';

  static String _formatDataForPrompt(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}