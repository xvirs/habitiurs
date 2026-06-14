import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/responsive.dart';
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
          final monthCard = CurrentMonthSummary(
            statistics: state.currentMonth,
            isRefreshing: state.isRefreshing,
          );
          final yearCard = YearlyStatisticsList(
            statistics: state.currentYear,
            isRefreshing: state.isRefreshing,
          );
          final chartCard = HistoricalChart(
            data: state.historicalData,
            isRefreshing: state.isRefreshing,
          );

          final isWide = Responsive.isWide(context);

          final Widget content = isWide
              // Pantalla ancha: dos columnas (mes+año | histórico).
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [monthCard, yearCard],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [chartCard],
                      ),
                    ),
                  ],
                )
              // Teléfono: columna única.
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [monthCard, yearCard, chartCard],
                );

          return RefreshIndicator(
            onRefresh: () => _refreshStatistics(context),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 1100 : 800),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content,
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
