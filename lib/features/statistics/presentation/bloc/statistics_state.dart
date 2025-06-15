
// lib/features/statistics/presentation/bloc/statistics_state.dart
import '../../domain/entities/statistics.dart';

abstract class StatisticsState {}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final MonthlyStatistics currentMonth;
  final List<MonthlyStatistics> currentYear;
  final List<HistoricalDataPoint> historicalData;

  StatisticsLoaded({
    required this.currentMonth,
    required this.currentYear,
    required this.historicalData,
  });
}

class StatisticsError extends StatisticsState {
  final String message;

  StatisticsError(this.message);
}
