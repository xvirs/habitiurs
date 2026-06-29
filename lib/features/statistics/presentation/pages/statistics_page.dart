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

  /// Dispara el recálculo y espera a que el bloc termine, para que el
  /// indicador del gesto pull-to-refresh gire hasta que haya datos frescos.
  Future<void> _refreshStatistics(BuildContext context) async {
    final bloc = context.read<StatisticsBloc>();
    bloc.add(RefreshStatistics());
    await bloc.stream
        .firstWhere((s) => s is! StatisticsLoaded || !s.isRefreshing)
        .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                    context.read<StatisticsBloc>().add(LoadStatistics());
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is StatisticsLoaded) {
          return RefreshIndicator(
            onRefresh: () => _refreshStatistics(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CurrentMonthSummary(
                          statistics: state.currentMonth,
                          isRefreshing: state.isRefreshing,
                        ),
                        YearlyStatisticsList(
                          statistics: state.currentYear,
                          isRefreshing: state.isRefreshing,
                        ),
                        HistoricalChart(
                          data: state.historicalData,
                          isRefreshing: state.isRefreshing,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
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
