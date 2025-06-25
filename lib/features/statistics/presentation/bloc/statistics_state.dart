// lib/features/statistics/presentation/bloc/statistics_state.dart - MODIFICADO

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
  final bool isRefreshing; // ✅ NUEVO: Indicador de refresco
  final String? errorMessage; // ✅ NUEVO: Mensaje de error para mantener en estado cargado

  StatisticsLoaded({
    required this.currentMonth,
    required this.currentYear,
    required this.historicalData,
    this.isRefreshing = false, // Valor por defecto
    this.errorMessage, // Valor por defecto
  });

  @override
  List<Object> get props => [currentMonth, currentYear, historicalData, isRefreshing, errorMessage ?? ''];

  // ✅ NUEVO: copyWith para actualizar estados de forma inmutable
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
      errorMessage: errorMessage, // Permitir borrar el mensaje si se pasa null
    );
  }
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}