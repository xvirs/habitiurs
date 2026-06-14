// lib/features/statistics/presentation/bloc/statistics_event.dart
abstract class StatisticsEvent {}

class LoadStatistics extends StatisticsEvent {}

/// Pull-to-refresh: sincroniza con la nube y recalcula (muestra indicador).
class RefreshStatistics extends StatisticsEvent {}

/// Relectura silenciosa de datos locales (al volver a la pestaña).
/// No sincroniza con la nube ni muestra spinners: mantiene el contenido
/// visible y lo reemplaza cuando llegan los datos frescos.
class RefreshStatisticsQuiet extends StatisticsEvent {}