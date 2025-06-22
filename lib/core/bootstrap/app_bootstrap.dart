// lib/core/bootstrap/app_bootstrap.dart - LÓGICA PURA (sin UI)
import 'package:firebase_core/firebase_core.dart';
import 'package:habitiurs/core/errors/app_error.dart';
import '../di/injection_container.dart';
import '../../firebase_options.dart';
import 'app_state.dart';

class AppBootstrap {
  Future<AppState> initialize() async {
    try {
      print('🚀 [Bootstrap] Iniciando aplicación...');
      
      await _initializeFirebase();
      await _initializeDependencies();
      
      print('✅ [Bootstrap] Inicialización exitosa');
      return AppState.success();
      
    } catch (e, stackTrace) {
      print('❌ [Bootstrap] Error crítico: $e');
      print('Stack trace: $stackTrace');
      
      return AppState.error(
        title: 'Error de inicialización',
        message: 'La aplicación no pudo inicializarse correctamente',
        technicalDetails: e.toString(),
        type: ErrorType.initialization,
      );
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ [Bootstrap] Firebase inicializado');
    } catch (e) {
      print('⚠️ [Bootstrap] Firebase falló: $e');
      // Continuar sin Firebase - modo offline
    }
  }

  Future<void> _initializeDependencies() async {
    try {
      final container = InjectionContainer();
      await container.init();
      print('✅ [Bootstrap] Dependencias inicializadas');
    } catch (e) {
      print('⚠️ [Bootstrap] DI falló: $e');
      // Continuar con servicios básicos
    }
  }
}