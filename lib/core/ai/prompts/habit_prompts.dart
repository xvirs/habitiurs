/// Habit-related prompts for AI
class HabitPrompts {
  static String buildEvaluationPrompt(String habit) => '''
Eres un experto en el seguimiento y la asistencia de hábitos mediante IA. Tu enfoque es ayudar al usuario a formular hábitos que sean fáciles de **trackear** y mantener diariamente.

HÁBITO: "$habit"

Criterios de Evaluación:
1. **Claridad:** ¿Es el hábito fácil de entender y recordar para marcar su cumplimiento diario?
2. **Viabilidad:** ¿Es realista y alcanzable para una persona común?
3. **Simplicidad:** ¿El hábito es conciso y directo, sin detalles excesivos?
4. **Enfoque en el Tracking:** ¿El hábito es adecuado para un seguimiento binario (hecho/no hecho)?

Instrucciones para la Respuesta:
* **Formato de Salida:** Responde siempre en **exactamente 2 líneas cortas y concisas**.
* **Contenido:**
    * **Línea 1:** Si el hábito es excelente, coloca: "Es un excelente hábito para trackear." 
      Si hay una sugerencia breve y útil, usa "✅" o "💡".
    * **Línea 2:** Siempre incluye "🎯 Probabilidad de éxito: [Alta/Media/Baja]".

Ejemplos:
- Es un excelente hábito para trackear.
  🎯 Probabilidad de éxito: Alta.

- ✅ Muy claro y viable para el seguimiento.
  🎯 Probabilidad de éxito: Alta.

- 💡 Simplifica la acción para facilitar el marcado diario.
  🎯 Probabilidad de éxito: Media.
''';

  static String buildAnalysisPrompt(Map<String, dynamic> habitData) => '''
Analiza estos patrones de hábitos de usuario:

DATOS DEL USUARIO:
${_formatDataForPrompt(habitData)}

Identifica:
1. Patrones de éxito (días/horarios mejores)
2. Obstáculos recurrentes
3. Recomendaciones específicas de mejora

Responde en máximo 4 líneas con insights accionables.
''';

  static String buildSuggestionPrompt(Map<String, dynamic> habitData) => '''
Basándote en estos datos de hábitos:

DATOS:
${_formatDataForPrompt(habitData)}

Sugiere mejoras específicas:
1. Ajustes de rutina
2. Estrategias de motivación
3. Modificaciones de entorno

Máximo 3 líneas, enfoque práctico.
''';

  static String _formatDataForPrompt(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}