// lib/features/statistics/data/models/statistics_model.dart
import '../../domain/entities/statistics.dart';

class MonthlyStatisticsModel extends MonthlyStatistics {
  const MonthlyStatisticsModel({
    required super.year,
    required super.month,
    required super.totalHabits,
    required super.completedCount,
    required super.skippedCount,
    required super.pendingCount,
    required super.weeks,
  });

  factory MonthlyStatisticsModel.fromMap(Map<String, dynamic> map) {
    return MonthlyStatisticsModel(
      year: map['year'] as int,
      month: map['month'] as int,
      totalHabits: map['total_habits'] as int,
      completedCount: map['completed_count'] as int,
      skippedCount: map['skipped_count'] as int,
      pendingCount: map['pending_count'] as int,
      weeks: [], // Se construyen por separado
    );
  }

  factory MonthlyStatisticsModel.fromEntity(MonthlyStatistics entity) {
    return MonthlyStatisticsModel(
      year: entity.year,
      month: entity.month,
      totalHabits: entity.totalHabits,
      completedCount: entity.completedCount,
      skippedCount: entity.skippedCount,
      pendingCount: entity.pendingCount,
      weeks: entity.weeks,
    );
  }
}

class WeeklyStatisticsModel extends WeeklyStatistics {
  const WeeklyStatisticsModel({
    required super.weekNumber,
    required super.startDate,
    required super.endDate,
    required super.completedCount,
    required super.skippedCount,
    required super.pendingCount,
  });

  factory WeeklyStatisticsModel.fromMap(Map<String, dynamic> map) {
    return WeeklyStatisticsModel(
      weekNumber: map['week_number'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      completedCount: map['completed_count'] as int,
      skippedCount: map['skipped_count'] as int,
      pendingCount: map['pending_count'] as int,
    );
  }
}

class HistoricalDataPointModel extends HistoricalDataPoint {
  const HistoricalDataPointModel({
    required super.date,
    required super.completedCount,
    required super.skippedCount,
    required super.completionRate,
  });

  factory HistoricalDataPointModel.fromMap(Map<String, dynamic> map) {
    final completed = map['completed_count'] as int;
    final skipped = map['skipped_count'] as int;
    final total = completed + skipped;
    final rate = total > 0 ? (completed / total) * 100 : 0.0;

    return HistoricalDataPointModel(
      date: DateTime.parse(map['date'] as String),
      completedCount: completed,
      skippedCount: skipped,
      completionRate: rate,
    );
  }
}