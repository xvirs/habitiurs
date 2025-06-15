import 'package:flutter/material.dart';
import 'habits_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1; // Inicia en Hábitos (centro)

  final List<Widget> _pages = [
    const AIAssistantPage(),  // Izquierda
    const HabitsPage(),       // Centro (página inicial)
    const StatisticsPage(),   // Derecha
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Asistente IA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }
}