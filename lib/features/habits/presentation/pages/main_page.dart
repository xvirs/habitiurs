// lib/features/main/presentation/pages/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/responsive.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_state.dart'; // Added
import 'package:habitiurs/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_bloc.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_event.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_state.dart';
import 'package:habitiurs/features/habits/presentation/pages/habits_page.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_event.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_state.dart'; // Added
import 'package:habitiurs/features/statistics/presentation/pages/statistics_page.dart';
import '../../../../shared/widgets/user_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'dart:async';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 1;
  StreamSubscription? _authBlocSyncSubscription;
  final Set<int> _visitedTabs = {1};
  bool _isSyncing = false;

  static const List<String> _pageTitles = [
    'Asistente IA',
    'Mis Hábitos',
    'Estadísticas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthSyncSubscription();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authBlocSyncSubscription?.cancel();
    super.dispose();
  }

  /// Al volver del segundo plano, recarga los datos en silencio (toma cambios
  /// hechos desde el widget de pantalla de inicio u otro dispositivo).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed || !mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<HabitBloc>().add(RefreshData());
    context.read<StatisticsBloc>().add(RefreshStatisticsQuiet());
  }

  void _setupAuthSyncSubscription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is AuthAuthenticated &&
          !authState.user.isGuest &&
          !authBloc.isSyncCompleted) {
        setState(() => _isSyncing = true);
      }
      _authBlocSyncSubscription = authBloc.initialSyncCompletedStream.listen(
        (_) => _onInitialSyncCompleted(),
      );
    });
  }

  void _onInitialSyncCompleted() {
    if (mounted) setState(() => _isSyncing = false);
    _loadDataForTab(0);
    _loadDataForTab(1);
    _loadDataForTab(2);
  }

  void _loadDataForTab(int index) {
    switch (index) {
      case 0:
        context.read<AIAssistantBloc>().add(LoadAIAssistantData());
        break;
      case 1:
        context.read<HabitBloc>().add(LoadHabits());
        break;
      case 2:
        context.read<StatisticsBloc>().add(LoadStatistics());
        break;
    }
  }

  void _refreshCurrentTab() {
    switch (_currentIndex) {
      case 0:
        context.read<AIAssistantBloc>().add(RefreshAIRecommendation());
        break;
      case 1:
        context.read<HabitBloc>().add(PullToRefresh());
        break;
      case 2:
        context.read<StatisticsBloc>().add(RefreshStatistics());
        break;
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      if (!_visitedTabs.contains(index)) {
        _visitedTabs.add(index);
        _loadDataForTab(index);
      } else {
        _silentRefreshTab(index);
      }
    }
  }

  /// Refresco barato (solo lectura local) al volver a una pestaña ya visitada,
  /// para que nunca muestre datos viejos. La recomendación IA queda fuera:
  /// regenerarla cuesta una llamada a Gemini y solo se hace manualmente.
  void _silentRefreshTab(int index) {
    switch (index) {
      case 1:
        context.read<HabitBloc>().add(RefreshData());
        break;
      case 2:
        context.read<StatisticsBloc>().add(RefreshStatisticsQuiet());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    final pages = Column(
      children: [
        if (_isSyncing)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [AIAssistantPage(), HabitsPage(), StatisticsPage()],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          _RefreshButton(
            currentIndex: _currentIndex,
            onRefresh: _refreshCurrentTab,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _UserAvatar(),
          ),
        ],
      ),
      drawer: UserDrawer(onDataSynced: _refreshCurrentTab),
      // Pantalla ancha (Fold desplegado / tablet): riel de navegación lateral.
      // Teléfono: barra de navegación inferior.
      body:
          isWide
              ? Row(
                children: [
                  _NavRail(currentIndex: _currentIndex, onTap: _onTabTapped),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: pages),
                ],
              )
              : pages,
      bottomNavigationBar:
          isWide
              ? null
              : _BottomNavBar(currentIndex: _currentIndex, onTap: _onTabTapped),
    );
  }
}

class _NavRail extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _NavRail({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.85,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.psychology_outlined),
          selectedIcon: Icon(Icons.psychology),
          label: Text('Asistente IA'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: Text('Hábitos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Estadísticas'),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onRefresh;

  const _RefreshButton({required this.currentIndex, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return switch (currentIndex) {
      0 => _AIRefreshButton(onRefresh: onRefresh),
      1 => _HabitsRefreshButton(onRefresh: onRefresh),
      2 => _StatisticsRefreshButton(onRefresh: onRefresh),
      _ => _RefreshIconButton(
        isLoading: false,
        onPressed: onRefresh,
        loadingTooltip: '',
        normalTooltip: 'Actualizar',
      ),
    };
  }
}

class _AIRefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _AIRefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIAssistantBloc, AIAssistantState>(
      builder: (context, state) {
        final isLoading =
            state is AIAssistantLoaded && state.isRecommendationLoading;
        return _RefreshIconButton(
          isLoading: isLoading,
          onPressed: isLoading ? null : onRefresh,
          loadingTooltip: 'Generando recomendación...',
          normalTooltip: 'Nueva recomendación',
        );
      },
    );
  }
}

class _StatisticsRefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _StatisticsRefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        final isLoading = state is StatisticsLoaded && state.isRefreshing;
        return _RefreshIconButton(
          isLoading: isLoading,
          onPressed: isLoading ? null : onRefresh,
          loadingTooltip: 'Actualizando estadísticas...',
          normalTooltip: 'Actualizar estadísticas',
        );
      },
    );
  }
}

class _HabitsRefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HabitsRefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        final isLoading = state is HabitLoaded && state.isRefreshing;
        // También mostrar loading si se está cargando inicialmente no cubierto por el esqueleto
        final isGlobalLoading = state is HabitLoading;

        return _RefreshIconButton(
          isLoading: isLoading || isGlobalLoading,
          onPressed: (isLoading || isGlobalLoading) ? null : onRefresh,
          loadingTooltip: 'Actualizando hábitos...',
          normalTooltip: 'Actualizar hábitos',
        );
      },
    );
  }
}

class _RefreshIconButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String loadingTooltip;
  final String normalTooltip;

  const _RefreshIconButton({
    required this.isLoading,
    required this.onPressed,
    required this.loadingTooltip,
    required this.normalTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onPressed,
      tooltip: isLoading ? loadingTooltip : normalTooltip,
      icon:
          isLoading
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
              : Icon(Icons.refresh, color: theme.colorScheme.primary),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return _AvatarContainer(
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: Colors.grey,
            ),
          );
        }

        final user = state.user;
        return _AvatarContainer(
          photoURL: user.photoURL,
          child:
              user.photoURL == null
                  ? Icon(
                    user.isGuest ? Icons.person_outline : Icons.person,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  )
                  : null,
        );
      },
    );
  }
}

class _AvatarContainer extends StatelessWidget {
  final String? photoURL;
  final Widget? child;

  const _AvatarContainer({this.photoURL, this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
          child: child,
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology_outlined),
          activeIcon: Icon(Icons.psychology),
          label: 'Asistente IA',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'Hábitos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Estadísticas',
        ),
      ],
    );
  }
}
