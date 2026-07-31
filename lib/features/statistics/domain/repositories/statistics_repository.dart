import '../entities/statistics.dart';

abstract class StatisticsRepository {
  Future<MonthlyStatistics> getCurrentMonthStatistics();
  Future<List<MonthlyStatistics>> getCurrentYearStatistics();
  Future<List<DailyActivity>> getDailyActivity();
  Future<MonthlyStatistics> getMonthStatistics(int year, int month);
}
