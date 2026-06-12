// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'features/app/presentation/pages/app_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AÑADIDO: Manejador global de errores de Flutter.
  // Esto capturará cualquier excepción no controlada que ocurra en el framework de Flutter
  // y la imprimirá en la consola, proporcionando una traza de pila detallada para la depuración.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(
      details,
    ); // Imprime el error completo en la consola
    // Opcional: Para aplicaciones en producción, aquí podrías enviar el error a un servicio
    // de reporte de fallos como Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  // 1. Configuración básica del sistema
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 2. Bootstrap de la aplicación
  final appBootstrap = AppBootstrap();
  final appState = await appBootstrap.initialize();

  // 3. Ejecutar aplicación
  runApp(AppPage(appState: appState));
}
