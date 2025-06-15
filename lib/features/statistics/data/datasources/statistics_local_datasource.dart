// lib/features/statistics/data/datasources/statistics_local_datasource.dart
import '../../../../core/database/database_helper.dart';
import '../../../../shared/enums/habit_status.dart';
import '../models/statistics_model.dart';

abstract class StatisticsLocalDatasource {
  Future<MonthlyStatisticsModel> getCurrentMonthStatistics();
  Future<List<MonthlyStatisticsModel>> getCurrentYearStatistics();
  Future<List<HistoricalDataPointModel>> getHistoricalData();
  Future<MonthlyStatisticsModel> getMonthStatistics(int year, int month);
}

class StatisticsLocalDatasourceImpl implements StatisticsLocalDatasource {
  final DatabaseHelper databaseHelper;

  StatisticsLocalDatasourceImpl({required this.databaseHelper});

  @override
  Future<MonthlyStatisticsModel> getCurrentMonthStatistics() async {
    final now = DateTime.now();
    return await getMonthStatistics(now.year, now.month);
  }

  @override
  Future<List<MonthlyStatisticsModel>> getCurrentYearStatistics() async {
    final now = DateTime.now();
    final List<MonthlyStatisticsModel> yearStatistics = [];

    for (int month = 1; month <= 12; month++) {
      final monthStats = await getMonthStatistics(now.year, month);
      // Solo agregar meses que tienen datos
      if (monthStats.totalHabits > 0) {
        yearStatistics.add(monthStats);
      }
    }

    return yearStatistics;
  }

  @override
  Future<List<HistoricalDataPointModel>> getHistoricalData() async {
    final db = await databaseHelper.database;

    const query = '''
      SELECT 
        strftime('%Y-%m', date) as date,
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as skipped_count
      FROM habit_entries
      WHERE status IN (?, ?)
      GROUP BY strftime('%Y-%m', date)
      ORDER BY date ASC
    ''';

    final result = await db.rawQuery(query, [
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
    ]);

    return result.map((map) {
      // Convertir YYYY-MM a DateTime (primer día del mes)
      final dateStr = map['date'] as String;
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);

      return HistoricalDataPointModel.fromMap({
        'date': date.toIso8601String(),
        'completed_count': map['completed_count'],
        'skipped_count': map['skipped_count'],
      });
    }).toList();
  }

  @override
  Future<MonthlyStatisticsModel> getMonthStatistics(int year, int month) async {
    final db = await databaseHelper.database;

    // Obtener el primer y último día del mes
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    // Consulta principal para estadísticas del mes
    const monthQuery = '''
      SELECT 
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as skipped_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as pending_count,
        COUNT(*) as total_habits
      FROM habit_entries
      WHERE date >= ? AND date <= ?
    ''';

    final monthResult = await db.rawQuery(monthQuery, [
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
      HabitStatus.pending.index,
      firstDay.toIso8601String().split('T')[0],
      lastDay.toIso8601String().split('T')[0],
    ]);

    final monthData = monthResult.first;

    // Obtener estadísticas por semana
    final weeks = await _getWeeklyStatistics(year, month, firstDay, lastDay);

    return MonthlyStatisticsModel(
      year: year,
      month: month,
      totalHabits: monthData['total_habits'] as int,
      completedCount: monthData['completed_count'] as int,
      skippedCount: monthData['skipped_count'] as int,
      pendingCount: monthData['pending_count'] as int,
      weeks: weeks,
    );
  }

  Future<List<WeeklyStatisticsModel>> _getWeeklyStatistics(
    int year,
    int month,
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    final db = await databaseHelper.database;
    final List<WeeklyStatisticsModel> weeks = [];

    // Encontrar el primer lunes del mes
    DateTime currentWeekStart = firstDay;
    while (currentWeekStart.weekday != 1) {
      // 1 = lunes
      currentWeekStart = currentWeekStart.add(const Duration(days: 1));
    }

    int weekNumber = 1;

    while (currentWeekStart.isBefore(lastDay)) {
      // Calcular el final de la semana (domingo)
      DateTime currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

      // Si el final de semana excede el mes, parar
      if (currentWeekEnd.isAfter(lastDay)) {
        break;
      }

      // Consultar estadísticas para esta semana
      const weekQuery = '''
      SELECT 
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as skipped_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as pending_count
      FROM habit_entries
      WHERE date >= ? AND date <= ?
    ''';

      final weekResult = await db.rawQuery(weekQuery, [
        HabitStatus.completed.index,
        HabitStatus.skipped.index,
        HabitStatus.pending.index,
        currentWeekStart.toIso8601String().split('T')[0],
        currentWeekEnd.toIso8601String().split('T')[0],
      ]);

      final weekData = weekResult.first;

      weeks.add(
        WeeklyStatisticsModel(
          weekNumber: weekNumber,
          startDate: currentWeekStart,
          endDate: currentWeekEnd,
          completedCount: weekData['completed_count'] as int,
          skippedCount: weekData['skipped_count'] as int,
          pendingCount: weekData['pending_count'] as int,
        ),
      );

      // Avanzar a la siguiente semana (siguiente lunes)
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
      weekNumber++;
    }

    return weeks;
  }
}
