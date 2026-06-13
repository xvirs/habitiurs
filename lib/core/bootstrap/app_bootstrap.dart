// lib/core/bootstrap/app_bootstrap.dart - LÓGICA PURA (sin UI)
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:habitiurs/core/errors/app_error.dart';
import '../di/injection_container.dart';
import '../notifications/notification_service.dart';
import '../../firebase_options.dart';
import 'app_state.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class AppBootstrap {
  Future<AppState> initialize() async {
    try {
      appLog('🚀 [Bootstrap] Iniciando aplicación...');

      await _initializeFirebase();
      await _initializeDependencies();
      await _initializeNotifications();

      appLog('✅ [Bootstrap] Inicialización exitosa');
      return AppState.success();
      
    } catch (e, stackTrace) {
      appLog('❌ [Bootstrap] Error crítico: $e');
      appLog('Stack trace: $stackTrace');
      
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
      appLog('✅ [Bootstrap] Firebase inicializado');
    } catch (e) {
      appLog('⚠️ [Bootstrap] Firebase falló: $e');
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
      appLog('✅ [Bootstrap] App Check activado');
    } catch (e) {
      appLog('⚠️ [Bootstrap] App Check falló: $e');
      // Continuar sin App Check - las llamadas a IA pueden fallar
    }
  }

  Future<void> _initializeDependencies() async {
    try {
      final container = InjectionContainer();
      await container.init();
      appLog('✅ [Bootstrap] Dependencias inicializadas');
    } catch (e) {
      appLog('⚠️ [Bootstrap] DI falló: $e');
      // Continuar con servicios básicos
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      appLog('✅ [Bootstrap] Notificaciones inicializadas');
    } catch (e) {
      appLog('⚠️ [Bootstrap] Notificaciones fallaron: $e');
      // Continuar sin notificaciones
    }
  }
}