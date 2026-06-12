// lib/core/bootstrap/app_bootstrap.dart - LÓGICA PURA (sin UI)
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:habitiurs/core/errors/app_error.dart';
import '../di/injection_container.dart';
import '../notifications/notification_service.dart';
import '../../firebase_options.dart';
import 'app_state.dart';

class AppBootstrap {
  Future<AppState> initialize() async {
    try {
      print('🚀 [Bootstrap] Iniciando aplicación...');

      await _initializeFirebase();
      await _initializeDependencies();
      await _initializeNotifications();

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
      await _activateAppCheck();
      print('✅ [Bootstrap] Firebase inicializado');
    } catch (e) {
      print('⚠️ [Bootstrap] Firebase falló: $e');
      // Continuar sin Firebase - modo offline
    }
  }

  Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );
      print('✅ [Bootstrap] App Check activado');
    } catch (e) {
      print('⚠️ [Bootstrap] App Check falló: $e');
      // Continuar sin App Check - las llamadas a IA pueden fallar
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

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      print('✅ [Bootstrap] Notificaciones inicializadas');
    } catch (e) {
      print('⚠️ [Bootstrap] Notificaciones fallaron: $e');
      // Continuar sin notificaciones
    }
  }
}