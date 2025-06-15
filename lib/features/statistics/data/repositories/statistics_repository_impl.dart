// lib/features/statistics/data/repositories/statistics_repository_impl.dart
import '../../domain/entities/statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_local_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsLocalDatasource localDatasource;

  StatisticsRepositoryImpl({required this.localDatasource});

  @override
  Future<MonthlyStatistics> getCurrentMonthStatistics() async {
    return await localDatasource.getCurrentMonthStatistics();
  }

  @override
  Future<List<MonthlyStatistics>> getCurrentYearStatistics() async {
    return await localDatasource.getCurrentYearStatistics();
  }

  @override
  Future<List<HistoricalDataPoint>> getHistoricalData() async {
    return await localDatasource.getHistoricalData();
  }

  @override
  Future<MonthlyStatistics> getMonthStatistics(int year, int month) async {
    return await localDatasource.getMonthStatistics(year, month);
  }
}