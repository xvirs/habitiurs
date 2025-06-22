// lib/features/habits/presentation/pages/main_page.dart - MODIFICADO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/user_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'habits_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Empezar en Hábitos (índice 1)
  
  // ✅ NUEVO: GlobalKey para acceder al HabitBloc
  final GlobalKey<HabitsPageState> _habitsPageKey = GlobalKey<HabitsPageState>();

  final List<String> _pageTitles = [
    'Asistente IA',
    'Mis Hábitos',
    'Estadísticas',
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ NUEVO: Lista de páginas con key para HabitsPage
    final List<Widget> pages = [
      const AIAssistantPage(),    // IA (índice 0)
      HabitsPage(key: _habitsPageKey), // Hábitos (índice 1) - CON KEY
      const StatisticsPage(),     // Estadísticas (índice 2)
    ];

    return Scaffold(
      // AppBar con avatar
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
      
      // ✅ MODIFICADO: Drawer con callback de sync
      drawer: UserDrawer(
        onDataSynced: _onDataSynced, // ← CALLBACK AGREGADO
      ),
      
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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

  // ✅ NUEVO: Callback que se ejecuta después del sync
  void _onDataSynced() {
    print('🔄 [MainPage] Recibido callback de sincronización');
    
    // Solo actualizar si estamos en la página de hábitos
    if (_currentIndex == 1 && _habitsPageKey.currentState != null) {
      print('✅ [MainPage] Refrescando HabitsPage...');
      _habitsPageKey.currentState!.refreshData();
    }
    
    // TODO: Si en el futuro queremos actualizar Statistics también:
    // if (_currentIndex == 2) { ... }
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