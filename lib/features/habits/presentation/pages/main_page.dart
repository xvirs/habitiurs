// lib/features/habits/presentation/pages/main_page.dart - RESTAURADO A SU ESTADO PREVIO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/user_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'habits_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../statistics/presentation/bloc/statistics_bloc.dart';
import '../../../statistics/presentation/bloc/statistics_event.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1;
  
  final GlobalKey<HabitsPageState> _habitsPageKey = GlobalKey<HabitsPageState>();

  final List<String> _pageTitles = [
    'Asistente IA',
    'Mis Hábitos',
    'Estadísticas',
  ];

  @override
  void initState() {
    super.initState();
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
        children: [
          const AIAssistantPage(),
          HabitsPage(key: _habitsPageKey),
          const StatisticsPage(),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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

  void _onDataSynced() {
    print('🔄 [MainPage] Recibido callback de sincronización');
    
    if (_currentIndex == 1 && _habitsPageKey.currentState != null) {
      print('✅ [MainPage] Refrescando HabitsPage...');
      _habitsPageKey.currentState!.refreshData();
    }
    
    if (_currentIndex == 2) {
      print('✅ [MainPage] Refrescando StatisticsPage...');
      context.read<StatisticsBloc>().add(RefreshStatistics());
    }
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