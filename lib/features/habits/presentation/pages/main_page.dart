// lib/features/main/presentation/pages/main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/responsive.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:habitiurs/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_bloc.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_event.dart';
import 'package:habitiurs/features/habits/presentation/pages/habits_page.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_event.dart';
import 'package:habitiurs/features/statistics/presentation/pages/statistics_page.dart';
import 'package:habitiurs/features/missions/presentation/bloc/mission_bloc.dart';
import 'package:habitiurs/features/missions/presentation/bloc/mission_event.dart';
import 'package:habitiurs/features/missions/presentation/bloc/mission_state.dart';
import 'package:habitiurs/features/missions/presentation/pages/missions_page.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import 'package:habitiurs/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:habitiurs/features/settings/presentation/bloc/settings_state.dart';
import '../../../../shared/widgets/user_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'dart:async';

/// Superficies primarias de la app. La barra inferior las muestra según si
/// Misiones está activa: OFF → [ai, habits, stats]; ON → [habits, stats,
/// missions] (el Asistente IA se accede desde el drawer).
enum TabKind { ai, habits, stats, missions }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  TabKind _current = TabKind.habits;
  StreamSubscription? _authBlocSyncSubscription;
  final Set<TabKind> _visited = {TabKind.habits};
  bool _isSyncing = false;

  // Se actualiza en cada build según missionsEnabled; lo usa _onTabTapped
  // para mapear el índice tocado a su TabKind.
  // Orden: Estadísticas (izq) · Hábitos (centro) · Misiones/Asistente (der).
  List<TabKind> _tabs = const [TabKind.stats, TabKind.habits, TabKind.ai];

  List<TabKind> _tabsFor(bool missionsEnabled) =>
      missionsEnabled
          ? const [TabKind.stats, TabKind.habits, TabKind.missions]
          : const [TabKind.stats, TabKind.habits, TabKind.ai];

  String _titleFor(TabKind k) => switch (k) {
    TabKind.ai => 'Asistente IA',
    TabKind.habits => 'Mis Hábitos',
    TabKind.stats => 'Estadísticas',
    TabKind.missions => 'Misiones',
  };

  Widget _pageFor(TabKind k) => switch (k) {
    TabKind.ai => const AIAssistantPage(),
    TabKind.habits => const HabitsPage(),
    TabKind.stats => const StatisticsPage(),
    TabKind.missions => const MissionsPage(),
  };

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
    context.read<MissionBloc>().add(const LoadMissions());
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
    _loadDataFor(TabKind.ai);
    _loadDataFor(TabKind.habits);
    _loadDataFor(TabKind.stats);
    _loadDataFor(TabKind.missions);
  }

  void _loadDataFor(TabKind k) {
    switch (k) {
      case TabKind.ai:
        context.read<AIAssistantBloc>().add(LoadAIAssistantData());
        break;
      case TabKind.habits:
        context.read<HabitBloc>().add(LoadHabits());
        break;
      case TabKind.stats:
        context.read<StatisticsBloc>().add(LoadStatistics());
        break;
      case TabKind.missions:
        context.read<MissionBloc>().add(const LoadMissions());
        break;
    }
  }

  void _refreshCurrentTab() {
    switch (_current) {
      case TabKind.ai:
        context.read<AIAssistantBloc>().add(RefreshAIRecommendation());
        break;
      case TabKind.habits:
        context.read<HabitBloc>().add(PullToRefresh());
        break;
      case TabKind.stats:
        context.read<StatisticsBloc>().add(RefreshStatistics());
        break;
      case TabKind.missions:
        context.read<MissionBloc>().add(const LoadMissions());
        break;
    }
  }

  void _onTabTapped(int index) {
    final kind = _tabs[index];
    if (_current == kind) return;
    setState(() => _current = kind);
    if (!_visited.contains(kind)) {
      _visited.add(kind);
      _loadDataFor(kind);
    } else {
      _silentRefreshTab(kind);
    }
  }

  /// Refresco barato (solo lectura local) al volver a una pestaña ya visitada,
  /// para que nunca muestre datos viejos. La recomendación IA queda fuera:
  /// regenerarla cuesta una llamada a Gemini y solo se hace manualmente.
  void _silentRefreshTab(TabKind k) {
    switch (k) {
      case TabKind.habits:
        context.read<HabitBloc>().add(RefreshData());
        break;
      case TabKind.stats:
        context.read<StatisticsBloc>().add(RefreshStatisticsQuiet());
        break;
      case TabKind.missions:
        context.read<MissionBloc>().add(const LoadMissions());
        break;
      case TabKind.ai:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    final settingsState = context.watch<SettingsBloc>().state;
    final showMissions =
        settingsState is SettingsLoaded &&
        settingsState.settings.missionsEnabled;

    _tabs = _tabsFor(showMissions);
    // Si la superficie activa ya no está en la barra (p. ej. estabas en el
    // Asistente IA y activaste Misiones), caemos a Hábitos.
    final current = _tabs.contains(_current) ? _current : TabKind.habits;
    final index = _tabs.indexOf(current);

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
            index: index,
            children: _tabs.map(_pageFor).toList(),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titleFor(current),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
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
                  _NavRail(
                    tabs: _tabs,
                    currentIndex: index,
                    onTap: _onTabTapped,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: pages),
                ],
              )
              : pages,
      bottomNavigationBar:
          isWide
              ? null
              : _BottomNavBar(
                tabs: _tabs,
                currentIndex: index,
                onTap: _onTabTapped,
              ),
    );
  }
}

/// Metadatos de navegación (icono normal, icono activo, etiqueta) por pestaña.
({IconData icon, IconData active, String label}) _navMetaFor(TabKind k) =>
    switch (k) {
      TabKind.ai => (
        icon: Icons.psychology_outlined,
        active: Icons.psychology,
        label: 'Asistente IA',
      ),
      TabKind.habits => (
        icon: Icons.check_circle_outline,
        active: Icons.check_circle,
        label: 'Hábitos',
      ),
      TabKind.stats => (
        icon: Icons.analytics_outlined,
        active: Icons.analytics,
        label: 'Estadísticas',
      ),
      TabKind.missions => (
        icon: Icons.flag_outlined,
        active: Icons.flag,
        label: 'Misiones',
      ),
    };

/// Construye el widget de icono de una pestaña; el de Misiones lleva badge.
Widget _navIconFor(TabKind k, {required bool active}) {
  final meta = _navMetaFor(k);
  final icon = active ? meta.active : meta.icon;
  if (k == TabKind.missions) return _MissionsTabIcon(icon: icon);
  return Icon(icon);
}

class _NavRail extends StatelessWidget {
  final List<TabKind> tabs;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavRail({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.85,
      destinations:
          tabs.map((k) {
            final meta = _navMetaFor(k);
            return NavigationRailDestination(
              icon: _navIconFor(k, active: false),
              selectedIcon: _navIconFor(k, active: true),
              label: Text(meta.label),
            );
          }).toList(),
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

/// Icono de la pestaña Misiones con un badge que cuenta las misiones
/// "accionables": pendientes que vencen hoy o ya están vencidas.
class _MissionsTabIcon extends StatelessWidget {
  final IconData icon;

  const _MissionsTabIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        final count = _actionableCount(state);
        final child = Icon(icon);
        if (count == 0) return child;
        return Badge(
          label: Text('$count'),
          backgroundColor: Theme.of(context).colorScheme.error,
          child: child,
        );
      },
    );
  }

  static int _actionableCount(MissionState state) {
    if (state is! MissionLoaded) return 0;
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    return state.missions.where((m) {
      if (m.isDone || m.dueDate == null) return false;
      return !AppDateUtils.getStartOfDay(m.dueDate!).isAfter(today);
    }).length;
  }
}

class _BottomNavBar extends StatelessWidget {
  final List<TabKind> tabs;
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNavBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items:
          tabs.map((k) {
            final meta = _navMetaFor(k);
            return BottomNavigationBarItem(
              icon: _navIconFor(k, active: false),
              activeIcon: _navIconFor(k, active: true),
              label: meta.label,
            );
          }).toList(),
    );
  }
}
