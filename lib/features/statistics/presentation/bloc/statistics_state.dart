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
  final List<DailyActivity> dailyActivity;

  /// Rachas, totales y patrón semanal derivados de la actividad diaria.
  late final ActivityInsights insights = ActivityInsights.fromDaily(
    dailyActivity,
  );
  final bool isRefreshing;
  final String? errorMessage;

  StatisticsLoaded({
    required this.currentMonth,
    required this.currentYear,
    required this.dailyActivity,
    this.isRefreshing = false,
    this.errorMessage,
  });

  @override
  List<Object> get props => [
    currentMonth,
    currentYear,
    dailyActivity,
    isRefreshing,
    errorMessage ?? '',
  ];

  StatisticsLoaded copyWith({
    MonthlyStatistics? currentMonth,
    List<MonthlyStatistics>? currentYear,
    List<DailyActivity>? dailyActivity,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return StatisticsLoaded(
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
      dailyActivity: dailyActivity ?? this.dailyActivity,
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
