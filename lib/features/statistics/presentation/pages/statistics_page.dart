// lib/features/statistics/presentation/pages/statistics_page.dart - CON IA INTEGRADA
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/current_month_summary.dart';
import '../widgets/yearly_statistics_list.dart';
import '../widgets/historical_chart.dart';
import '../widgets/ai_statistics_insights.dart'; // 🆕 Widget de IA

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InjectionContainer().statisticsBloc..add(LoadStatistics()),
      child: const StatisticsView(),
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        shadowColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StatisticsBloc>().add(RefreshStatistics());
            },
          ),
        ],
      ),
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
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
              onRefresh: () async {
                context.read<StatisticsBloc>().add(RefreshStatistics());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🆕 NUEVO: Insights de IA como primer componente
                    AIStatisticsInsights(
                      currentMonth: state.currentMonth,
                      yearlyStats: state.currentYear,
                      historicalData: state.historicalData,
                    ),

                    // Componente 1: Resumen del mes actual con semanas
                    CurrentMonthSummary(statistics: state.currentMonth),

                    // Componente 2: Lista scrolleable del año actual
                    YearlyStatisticsList(statistics: state.currentYear),

                    // Componente 3: Gráfico histórico
                    HistoricalChart(data: state.historicalData),

                    // Espaciado final
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }

          // Estado inicial
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
      ),
    );
  }
}