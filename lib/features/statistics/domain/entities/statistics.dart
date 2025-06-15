// lib/features/statistics/domain/entities/statistics.dart
class MonthlyStatistics {
  final int year;
  final int month;
  final int totalHabits;
  final int completedCount;
  final int skippedCount;
  final int pendingCount;
  final List<WeeklyStatistics> weeks;

  const MonthlyStatistics({
    required this.year,
    required this.month,
    required this.totalHabits,
    required this.completedCount,
    required this.skippedCount,
    required this.pendingCount,
    required this.weeks,
  });

  double get completionRate => 
      totalHabits > 0 ? (completedCount / totalHabits) * 100 : 0.0;

  String get monthName {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

class WeeklyStatistics {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int completedCount;
  final int skippedCount;
  final int pendingCount;

  const WeeklyStatistics({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.completedCount,
    required this.skippedCount,
    required this.pendingCount,
  });

  int get totalEntries => completedCount + skippedCount + pendingCount;
  
  double get completionRate => 
      totalEntries > 0 ? (completedCount / totalEntries) * 100 : 0.0;
}

class HistoricalDataPoint {
  final DateTime date;
  final int completedCount;
  final int skippedCount;
  final double completionRate;

  const HistoricalDataPoint({
    required this.date,
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
  });
}