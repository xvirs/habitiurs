import 'package:equatable/equatable.dart';
import '../../domain/entities/statistics.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final MonthlyStatistics currentMonth;
  final List<MonthlyStatistics> currentYear;
  final List<HistoricalDataPoint> historicalData;
  final bool isRefreshing;
  final String? errorMessage;

  StatisticsLoaded({
    required this.currentMonth,
    required this.currentYear,
    required this.historicalData,
    this.isRefreshing = false,
    this.errorMessage,
  });

  @override
  List<Object> get props => [currentMonth, currentYear, historicalData, isRefreshing, errorMessage ?? ''];

  StatisticsLoaded copyWith({
    MonthlyStatistics? currentMonth,
    List<MonthlyStatistics>? currentYear,
    List<HistoricalDataPoint>? historicalData,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return StatisticsLoaded(
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
      historicalData: historicalData ?? this.historicalData,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}