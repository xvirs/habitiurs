// lib/core/ai/models/ai_context_builder.dart
/// Builder para generar contextos específicos por feature
class AIContextBuilder {
  
  /// HABITS CONTEXT
  static Map<String, dynamic> buildHabitEvaluationContext(String habitName) {
    return {
      'feature': 'habits',
      'action': 'evaluation',
      'habit_name': habitName,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildHabitAnalysisContext({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required List<String> strugglingHabits,
  }) {
    return {
      'feature': 'habits',
      'action': 'analysis',
      'habit_names': habitNames,
      'completion_rates': completionRates,
      'current_streak': currentStreak,
      'struggling_habits': strugglingHabits,
      'total_habits': habitNames.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// STATISTICS CONTEXT
  static Map<String, dynamic> buildStatsAnalysisContext({
    required double monthlyCompletionRate,
    required List<double> weeklyRates,
    required int totalDaysTracked,
    required Map<String, double> habitPerformance,
  }) {
    return {
      'feature': 'statistics',
      'action': 'analysis',
      'monthly_completion_rate': monthlyCompletionRate,
      'weekly_rates': weeklyRates,
      'total_days_tracked': totalDaysTracked,
      'habit_performance': habitPerformance,
      'average_weekly_rate': weeklyRates.isNotEmpty 
          ? weeklyRates.reduce((a, b) => a + b) / weeklyRates.length 
          : 0.0,
      'trend_direction': weeklyRates.length >= 2 
          ? (weeklyRates.last - weeklyRates.first > 0 ? 'positive' : 'negative')
          : 'stable',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildPredictionContext({
    required List<Map<String, dynamic>> historicalData,
    required List<String> currentHabits,
    required double currentTrend,
  }) {
    return {
      'feature': 'statistics',
      'action': 'prediction',
      'historical_data': historicalData,
      'current_habits': currentHabits,
      'current_trend': currentTrend,
      'data_points_count': historicalData.length,
      'prediction_confidence': historicalData.length >= 4 ? 'high' : 'medium',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildTrendAnalysisContext({
    required List<Map<String, dynamic>> monthlyData,
    required double currentRate,
    required double previousRate,
  }) {
    return {
      'feature': 'statistics',
      'action': 'trend_analysis',
      'monthly_data': monthlyData,
      'current_rate': currentRate,
      'previous_rate': previousRate,
      'rate_change': currentRate - previousRate,
      'trend_direction': currentRate > previousRate ? 'improving' : 'declining',
      'data_months': monthlyData.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// AI ASSISTANT CONTEXT (mantener compatibilidad)
  static Map<String, dynamic> buildPersonalRecommendationContext({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required int longestStreak,
    required List<String> strugglingHabits,
    required int totalDaysTracked,
    required DateTime lastActiveDate,
  }) {
    // Calcular métricas adicionales
    final avgCompletionRate = completionRates.values.isNotEmpty 
        ? completionRates.values.reduce((a, b) => a + b) / completionRates.values.length
        : 0.0;
    
    final daysSinceLastActive = DateTime.now().difference(lastActiveDate).inDays;
    
    return {
      'feature': 'ai_assistant',
      'action': 'personal_recommendation',
      'habit_names': habitNames,
      'completion_rates': completionRates,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'struggling_habits': strugglingHabits,
      'total_days_tracked': totalDaysTracked,
      'last_active_date': lastActiveDate.toIso8601String(),
      'days_since_last_active': daysSinceLastActive,
      'average_completion_rate': avgCompletionRate,
      'performance_level': _getPerformanceLevel(avgCompletionRate),
      'streak_status': _getStreakStatus(currentStreak, longestStreak),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildMotivationalContext({
    required int currentStreak,
    required double weeklyProgress,
    required String userMood, // 'good', 'struggling', 'motivated'
  }) {
    return {
      'feature': 'ai_assistant',
      'action': 'motivational_message',
      'current_streak': currentStreak,
      'weekly_progress': weeklyProgress,
      'user_mood': userMood,
      'encouragement_type': _getEncouragementType(currentStreak, weeklyProgress),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // HELPERS PRIVADOS
  static String _getPerformanceLevel(double avgRate) {
    if (avgRate >= 0.8) return 'excellent';
    if (avgRate >= 0.6) return 'good';
    if (avgRate >= 0.4) return 'improving';
    return 'needs_focus';
  }

  static String _getStreakStatus(int current, int longest) {
    if (current == 0) return 'broken';
    if (current >= longest) return 'record';
    if (current >= longest * 0.8) return 'strong';
    return 'building';
  }

  static String _getEncouragementType(int streak, double progress) {
    if (streak == 0 && progress < 0.3) return 'recovery';
    if (streak > 7 && progress > 0.7) return 'celebration';
    if (progress < 0.5) return 'motivation';
    return 'maintenance';
  }

  /// UTILITY METHODS
  static Map<String, dynamic> addCommonMetadata(Map<String, dynamic> context) {
    return {
      ...context,
      'app_version': '1.0.0',
      'platform': 'flutter',
      'generated_at': DateTime.now().toIso8601String(),
      'context_version': '1.0',
    };
  }

  static Map<String, dynamic> sanitizeContext(Map<String, dynamic> context) {
    // Remover datos sensibles o innecesarios
    final sanitized = Map<String, dynamic>.from(context);
    
    // Remover información personal si existe
    sanitized.remove('user_email');
    sanitized.remove('device_id');
    
    // Limitar tamaño de arrays grandes
    if (sanitized['historical_data'] is List) {
      final List data = sanitized['historical_data'];
      if (data.length > 12) {
        sanitized['historical_data'] = data.take(12).toList();
        sanitized['data_truncated'] = true;
      }
    }
    
    return sanitized;
  }
}