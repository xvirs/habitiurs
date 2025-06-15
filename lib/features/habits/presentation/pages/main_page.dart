// lib/features/habits/presentation/pages/main_page.dart - NAVEGACIÓN REORGANIZADA
import 'package:flutter/material.dart';
import 'habits_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // CAMBIO: Empezar en Hábitos (índice 1)

  final List<Widget> _pages = [
    const AIAssistantPage(),    // CAMBIO: IA a la izquierda (índice 0)
    const HabitsPage(),         // CAMBIO: Hábitos al centro (índice 1)
    const StatisticsPage(),     // CAMBIO: Estadísticas a la derecha (índice 2)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // AGREGAR: Para que se vean todos los íconos
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          // REORGANIZADO: IA - Hábitos - Estadísticas
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology), // Ícono lleno cuando está activo
            label: 'Asistente IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle), // Ícono lleno cuando está activo
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics), // Ícono lleno cuando está activo
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}