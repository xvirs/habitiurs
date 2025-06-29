// lib/features/statistics/presentation/bloc/statistics_event.dart
abstract class StatisticsEvent {}

class LoadStatistics extends StatisticsEvent {}

class LoadStatisticsWithSync extends StatisticsEvent {} // ADDED

class RefreshStatistics extends StatisticsEvent {}