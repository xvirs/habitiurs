import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/widgets/yearly_statistics_list.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/current_month_summary.dart';
import '../widgets/historical_chart.dart';

// FIXED: Convertir StatisticsPage a StatefulWidget para gestionar initState/dispose
// si necesita _today o AutomaticKeepAliveClientMixin, aunque para StatisticsPage
// usualmente no es necesario si no tiene estado local que mantener.
// Si no hay estado local, StatelessWidget es preferible.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIXED: Se remueve el BlocProvider local. StatisticsBloc ya es provisto por AppPage.
    return StatisticsContent();
  }
}

class StatisticsContent extends StatelessWidget {
  const StatisticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fixed: Ahora usa BlocBuilder directamente ya que el BlocProvider está en AppPage.
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StatisticsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar estadísticas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // FIXED: Disparar LoadStatistics a través del contexto
                    context.read<StatisticsBloc>().add(LoadStatistics());
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is StatisticsLoaded) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  print('🔄 [StatisticsPage] Pull-to-refresh activado');
                  // FIXED: Disparar RefreshStatistics a través del contexto
                  if (context.mounted) {
                    context.read<StatisticsBloc>().add(RefreshStatistics());
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      child: CurrentMonthSummary(
                        statistics: state.currentMonth,
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: YearlyStatisticsList(
                        statistics: state.currentYear,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: HistoricalChart(data: state.historicalData),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Cargando estadísticas...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
