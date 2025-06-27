class PromptFormatter {
  static String formatMapForPrompt(Map<String, dynamic> data) =>
      data.entries.map((e) => '${e.key}: ${e.value}').join('\n');

  static String formatListForPrompt(List<dynamic> data, {String separator = ', '}) =>
      data.join(separator);

  static String formatCompletionRates(Map<String, double> rates) =>
      rates.entries
          .map((e) => '${e.key}: ${(e.value * 100).toStringAsFixed(1)}%')
          .join('\n');

  static String formatStatistics(Map<String, dynamic> stats) {
    final formatted = <String>[];
    
    for (final entry in stats.entries) {
      if (entry.value is double) {
        formatted.add('${entry.key}: ${(entry.value as double).toStringAsFixed(2)}');
      } else if (entry.value is List) {
        formatted.add('${entry.key}: ${formatListForPrompt(entry.value)}');
      } else {
        formatted.add('${entry.key}: ${entry.value}');
      }
    }
    
    return formatted.join('\n');
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    
    final truncated = text.substring(0, maxLength - 3);
    final lastSpace = truncated.lastIndexOf(' ');
    
    return lastSpace > maxLength * 0.8
        ? '${truncated.substring(0, lastSpace)}...'
        : '$truncated...';
  }

  static String sanitizeUserInput(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), ' ');
}