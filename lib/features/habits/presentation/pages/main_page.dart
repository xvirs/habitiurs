// lib/features/habits/presentation/pages/main_page.dart - CON DRAWER
import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/user_drawer.dart';
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

  final List<Widget> _pages = [
    const AIAssistantPage(),    // IA a la izquierda (índice 0)
    const HabitsPage(),         // Hábitos al centro (índice 1)
    const StatisticsPage(),     // Estadísticas a la derecha (índice 2)
  ];

  final List<String> _pageTitles = [
    'Asistente IA',
    'Mis Hábitos',
    'Estadísticas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Agregar AppBar con avatar
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
          // ✅ Avatar de usuario que abre el drawer
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildUserAvatar(),
          ),
        ],
      ),
      
      // ✅ Agregar Drawer
      drawer: const UserDrawer(),
      
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
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

  Widget _buildUserAvatar() {
    final authService = InjectionContainer().authService;
    final user = authService.currentUser;
    final isGuest = user?.preferences?['mode'] == 'guest';
    
    return GestureDetector(
      onTap: () {
        // Abrir drawer programáticamente
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
          backgroundImage: user?.photoURL != null 
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL == null
              ? Icon(
                  isGuest ? Icons.person_outline : Icons.person,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
      ),
    );
  }
}