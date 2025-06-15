// lib/core/di/injection_container.dart - VERSIÓN CORREGIDA
import '../../core/database/database_helper.dart';
import '../../features/habits/data/datasources/habit_local_datasource.dart';
import '../../features/habits/data/repositories/habit_repository_impl.dart';
import '../../features/habits/domain/repositories/habit_repository.dart';
import '../../features/habits/domain/usecases/create_habit.dart';
import '../../features/habits/domain/usecases/delete_habit.dart';
import '../../features/habits/domain/usecases/get_all_habits.dart';
import '../../features/habits/domain/usecases/get_week_entries.dart';
import '../../features/habits/domain/usecases/toggle_habit_entry.dart';
import '../../features/habits/presentation/bloc/habit_bloc.dart';

import '../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/get_current_month_statistics.dart';
import '../../features/statistics/presentation/bloc/statistics_bloc.dart';

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  // Database
  late final DatabaseHelper _databaseHelper;

  // DataSources
  late final HabitLocalDataSource _habitLocalDataSource;
  late final StatisticsLocalDatasource _statisticsLocalDatasource;

  // Repositories
  late final HabitRepository _habitRepository;
  late final StatisticsRepository _statisticsRepository;

  // Use Cases - Habits
  late final GetAllHabits _getAllHabits;
  late final CreateHabit _createHabit;
  late final GetWeekEntries _getWeekEntries;
  late final ToggleHabitEntry _toggleHabitEntry;
  late final DeleteHabit _deleteHabit;

  // Use Cases - Statistics
  late final GetCurrentMonthStatistics _getCurrentMonthStatistics;
  late final GetCurrentYearStatistics _getCurrentYearStatistics;
  late final GetHistoricalData _getHistoricalData;

  void init() {
    // Database - Usar la implementación concreta
    _databaseHelper = SqliteDatabaseHelper();

    // DataSources
    _habitLocalDataSource = HabitLocalDataSourceImpl(_databaseHelper);
    _statisticsLocalDatasource = StatisticsLocalDatasourceImpl(databaseHelper: _databaseHelper);

    // Repositories
    _habitRepository = HabitRepositoryImpl(_habitLocalDataSource);
    _statisticsRepository = StatisticsRepositoryImpl(localDatasource: _statisticsLocalDatasource);

    // Use Cases - Habits
    _getAllHabits = GetAllHabits(_habitRepository);
    _createHabit = CreateHabit(_habitRepository);
    _getWeekEntries = GetWeekEntries(_habitRepository);
    _toggleHabitEntry = ToggleHabitEntry(_habitRepository);
    _deleteHabit = DeleteHabit(_habitRepository);

    // Use Cases - Statistics
    _getCurrentMonthStatistics = GetCurrentMonthStatistics(_statisticsRepository);
    _getCurrentYearStatistics = GetCurrentYearStatistics(_statisticsRepository);
    _getHistoricalData = GetHistoricalData(_statisticsRepository);
  }

  HabitBloc get habitBloc => HabitBloc(
    getAllHabits: _getAllHabits,
    createHabit: _createHabit,
    getWeekEntries: _getWeekEntries,
    toggleHabitEntry: _toggleHabitEntry,
    deleteHabit: _deleteHabit,
  );

  StatisticsBloc get statisticsBloc => StatisticsBloc(
    getCurrentMonthStatistics: _getCurrentMonthStatistics,
    getCurrentYearStatistics: _getCurrentYearStatistics,
    getHistoricalData: _getHistoricalData,
  );
}