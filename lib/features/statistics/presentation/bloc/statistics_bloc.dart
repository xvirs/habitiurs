// lib/features/statistics/presentation/bloc/statistics_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/domain/entities/statistics.dart';
import '../../domain/usecases/get_current_month_statistics.dart';
import 'statistics_event.dart';
import 'statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final GetCurrentMonthStatistics getCurrentMonthStatistics;
  final GetCurrentYearStatistics getCurrentYearStatistics;
  final GetHistoricalData getHistoricalData;

  StatisticsBloc({
    required this.getCurrentMonthStatistics,
    required this.getCurrentYearStatistics,
    required this.getHistoricalData,
  }) : super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshStatistics>(_onRefreshStatistics);
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    
    try {
      // Cargar todos los datos en paralelo
      final results = await Future.wait([
        getCurrentMonthStatistics(),
        getCurrentYearStatistics(),
        getHistoricalData(),
      ]);

      emit(StatisticsLoaded(
        currentMonth: results[0] as MonthlyStatistics,
        currentYear: results[1] as List<MonthlyStatistics>,
        historicalData: results[2] as List<HistoricalDataPoint>,
      ));
    } catch (e) {
      emit(StatisticsError('Error al cargar estadísticas: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshStatistics(
    RefreshStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    // Mantener el estado actual mientras se actualiza
    final currentState = state;
    
    try {
      final results = await Future.wait([
        getCurrentMonthStatistics(),
        getCurrentYearStatistics(),
        getHistoricalData(),
      ]);

      emit(StatisticsLoaded(
        currentMonth: results[0] as MonthlyStatistics,
        currentYear: results[1] as List<MonthlyStatistics>,
        historicalData: results[2] as List<HistoricalDataPoint>,
      ));
    } catch (e) {
      // Si hay error, mantener el estado anterior
      if (currentState is StatisticsLoaded) {
        emit(currentState);
      } else {
        emit(StatisticsError('Error al actualizar estadísticas: ${e.toString()}'));
      }
    }
  }
}