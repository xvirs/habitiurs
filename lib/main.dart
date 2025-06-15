import 'package:flutter/material.dart';
import 'core/database/database_helper.dart';
import 'core/di/injection_container.dart';
import 'features/habits/presentation/pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar inyección de dependencias
  InjectionContainer().init();
  
  // Inicializar base de datos usando la implementación concreta
  await SqliteDatabaseHelper().database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitiurs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}