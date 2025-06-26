import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:habitiurs/features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import 'package:habitiurs/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_bloc.dart';
import 'package:habitiurs/features/habits/presentation/bloc/habit_event.dart';
import 'package:habitiurs/features/habits/presentation/pages/habits_page.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/bloc/statistics_event.dart';
import 'package:habitiurs/features/statistics/presentation/pages/statistics_page.dart';
import '../../../../shared/widgets/user_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1;

  final List<String> _pageTitles = [
    'Asistente IA',
    'Mis Hábitos',
    'Estadísticas',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialDataForCurrentTab(_currentIndex);
    });
  }

  void _loadInitialDataForCurrentTab(int index) {
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildUserAvatar(),
          ),
        ],
      ),
      drawer: UserDrawer(
        onDataSynced: _onDataSynced,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AIAssistantPage(),
          HabitsPage(),
          StatisticsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (_currentIndex != index) {
              _currentIndex = index;
              _refreshDataForTab(index);
            }
          });
        },
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
      ),
    );
  }

  void _refreshDataForTab(int index) {
    switch (index) {
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

  void _onDataSynced() {
    _refreshDataForTab(_currentIndex);
  }

  Widget _buildUserAvatar() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return _buildAvatarContainer(
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: Colors.grey,
            ),
          );
        }

        final user = state.user;
        final isGuest = user.isGuest;

        return _buildAvatarContainer(
          photoURL: user.photoURL,
          child: user.photoURL == null
              ? Icon(
                  isGuest ? Icons.person_outline : Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        );
      },
    );
  }

  Widget _buildAvatarContainer({
    String? photoURL,
    Widget? child,
  }) {
    return GestureDetector(
      onTap: () {
        Scaffold.of(context).openDrawer();
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: photoURL != null
              ? NetworkImage(photoURL)
              : null,
          child: child,
        ),
      ),
    );
  }
}
