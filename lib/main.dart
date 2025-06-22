// lib/main.dart - FINAL RECOMENDADO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'features/app/presentation/pages/app_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Configuración básica del sistema
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // 2. Bootstrap de la aplicación
  final appBootstrap = AppBootstrap();
  final appState = await appBootstrap.initialize();
  
  // 3. Ejecutar aplicación
  runApp(AppPage(appState: appState));
}
