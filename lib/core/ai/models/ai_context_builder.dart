/// Context builder for AI requests
class AIContextBuilder {
  static Map<String, dynamic> buildHabitEvaluationContext(String habitName) => {
    'feature': 'habits',
    'action': 'evaluation',
    'habit_name': habitName,
    'timestamp': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> buildHabitAnalysisContext({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required List<String> strugglingHabits,
  }) => {
    'feature': 'habits',
    'action': 'analysis',
    'habit_names': habitNames,
    'completion_rates': completionRates,
    'current_streak': currentStreak,
    'struggling_habits': strugglingHabits,
    'total_habits': habitNames.length,
    'timestamp': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> buildStatsAnalysisContext({
    required double monthlyCompletionRate,
    required List<double> weeklyRates,
    required int totalDaysTracked,
    required Map<String, double> habitPerformance,
  }) => {
    'feature': 'statistics',
    'action': 'analysis',
    'monthly_completion_rate': monthlyCompletionRate,
    'weekly_rates': weeklyRates,
    'total_days_tracked': totalDaysTracked,
    'habit_performance': habitPerformance,
    'average_weekly_rate': weeklyRates.isNotEmpty
        ? weeklyRates.reduce((a, b) => a + b) / weeklyRates.length
        : 0.0,
    'trend_direction': _getTrendDirection(weeklyRates),
    'timestamp': DateTime.now().toIso8601String(),
  };

  static Map<String, dynamic> buildPersonalRecommendationContext({
    required List<String> habitNames,
    required Map<String, double> completionRates,
    required int currentStreak,
    required int longestStreak,
    required List<String> strugglingHabits,
    required int totalDaysTracked,
    required DateTime lastActiveDate,
  }) {
    final avgCompletionRate = completionRates.values.isNotEmpty
        ? completionRates.values.reduce((a, b) => a + b) / completionRates.values.length
        : 0.0;
    
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
      'days_since_last_active': DateTime.now().difference(lastActiveDate).inDays,
      'average_completion_rate': avgCompletionRate,
      'performance_level': _getPerformanceLevel(avgCompletionRate),
      'streak_status': _getStreakStatus(currentStreak, longestStreak),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> sanitizeContext(Map<String, dynamic> context) {
    final sanitized = Map<String, dynamic>.from(context);
    
    // Remove sensitive information
    sanitized.remove('user_email');
    sanitized.remove('device_id');
    
    // Limit large arrays
    if (sanitized['historical_data'] is List) {
      final List data = sanitized['historical_data'];
      if (data.length > 12) {
        sanitized['historical_data'] = data.take(12).toList();
        sanitized['data_truncated'] = true;
      }
    }
    
    return sanitized;
  }

  static String _getTrendDirection(List<double> weeklyRates) {
    if (weeklyRates.length < 2) return 'stable';
    return weeklyRates.last > weeklyRates.first ? 'positive' : 'negative';
  }

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
}