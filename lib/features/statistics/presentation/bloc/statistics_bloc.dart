import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/domain/entities/statistics.dart';
import '../../domain/usecases/get_current_month_statistics.dart';
import '../../domain/usecases/get_current_year_statistics.dart'; // ADDED
import '../../domain/usecases/get_historical_data.dart'; // ADDED
import 'statistics_event.dart';
import 'statistics_state.dart';

import '../../../../core/sync/repositories/sync_repository.dart'; // ADDED

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final GetCurrentMonthStatistics getCurrentMonthStatistics;
  final GetCurrentYearStatistics getCurrentYearStatistics;
  final GetHistoricalData getHistoricalData;
  final SyncRepository syncRepository; // ADDED

  StatisticsBloc({
    required this.getCurrentMonthStatistics,
    required this.getCurrentYearStatistics,
    required this.getHistoricalData,
    required this.syncRepository, // ADDED
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
      final results = await Future.wait([
        getCurrentMonthStatistics(),
        getCurrentYearStatistics(),
        getHistoricalData(),
      ]);
      emit(
        StatisticsLoaded(
          currentMonth: results[0] as MonthlyStatistics,
          currentYear: results[1] as List<MonthlyStatistics>,
          historicalData: results[2] as List<HistoricalDataPoint>,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      emit(StatisticsError('Error al cargar estadísticas: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshStatistics(
    RefreshStatistics event,
    Emitter<StatisticsState> emit,
  ) async {
    final currentState = state;
    try {
      if (currentState is StatisticsLoaded) {
        emit(currentState.copyWith(isRefreshing: true));
      } else {
        emit(StatisticsLoading());
      }

      // Realiza una sincronización completa usando el repositorio inyectado
      await syncRepository.syncAll();

      final results = await Future.wait([
        getCurrentMonthStatistics(),
        getCurrentYearStatistics(),
        getHistoricalData(),
      ]);
      emit(
        StatisticsLoaded(
          currentMonth: results[0] as MonthlyStatistics,
          currentYear: results[1] as List<MonthlyStatistics>,
          historicalData: results[2] as List<HistoricalDataPoint>,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      if (currentState is StatisticsLoaded) {
        emit(
          currentState.copyWith(
            isRefreshing: false,
            errorMessage: 'Error al actualizar: ${e.toString()}',
          ),
        );
      } else {
        emit(
          StatisticsError('Error al actualizar estadísticas: ${e.toString()}'),
        );
      }
    }
  }
}
