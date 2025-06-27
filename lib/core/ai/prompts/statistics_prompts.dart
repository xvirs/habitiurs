class StatisticsPrompts {
  static String buildAnalysisPrompt(Map<String, dynamic> statsData) => '''
Analiza estas estadísticas de progreso de hábitos:

ESTADÍSTICAS:
${_formatDataForPrompt(statsData)}

Proporciona:
1. Interpretación del progreso actual
2. Tendencias positivas identificadas
3. Áreas de oportunidad específicas
4. Meta realista para el próximo mes

Máximo 4 líneas, enfoque en insights accionables.
''';

  static String buildPredictionPrompt(Map<String, dynamic> predictionData) => '''
Basándote en estos datos históricos de hábitos:

DATOS HISTÓRICOS:
${_formatDataForPrompt(predictionData)}

Predice:
1. Probabilidad de mantener progreso actual
2. Hábitos con mayor riesgo de abandono
3. Estrategias preventivas específicas

Respuesta concisa en 3 líneas máximo.
''';

  static String buildTrendAnalysisPrompt(Map<String, dynamic> trendData) => '''
Analiza estas tendencias de hábitos:

DATOS DE TENDENCIAS:
${_formatDataForPrompt(trendData)}

Identifica:
1. Patrones estacionales o cíclicos
2. Factores que influyen en el rendimiento
3. Oportunidades de optimización

Máximo 3 líneas con insights específicos.
''';

  static String _formatDataForPrompt(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
}