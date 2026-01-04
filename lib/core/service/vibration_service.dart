// lib/core/services/vibration_service.dart
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Servicio de vibraciones usando solo APIs nativas de Flutter
/// No requiere dependencias externas y es compatible con todas las versiones
class VibrationService {
  // Control para evitar vibraciones muy frecuentes
  static DateTime? _lastVibration;
  static const _minInterval = Duration(milliseconds: 50);

  /// Verifica si es seguro vibrar (evita spam)
  static bool _canVibrate() {
    if (kIsWeb) return false;
    
    final now = DateTime.now();
    if (_lastVibration != null && 
        now.difference(_lastVibration!) < _minInterval) {
      return false;
    }
    _lastVibration = now;
    return true;
  }

  /// Vibración ligera para toggles/completar hábitos (éxito)
  static Future<void> success() async {
    if (!_canVibrate()) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración media para acciones importantes (crear hábito)
  static Future<void> medium() async {
    if (!_canVibrate()) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración fuerte para advertencias (eliminar)
  static Future<void> warning() async {
    if (!_canVibrate()) return;
    
    try {
      // Vibración más agresiva - doble heavy impact
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración de selección para navegación
  static Future<void> selection() async {
    if (!_canVibrate()) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración personalizada para errores (doble vibración)
  static Future<void> error() async {
    if (kIsWeb) return;
    
    try {
      // Vibración muy agresiva - triple pattern
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_canVibrate()) {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración EXTRA agresiva para confirmación de eliminación
  static Future<void> deleteConfirmation() async {
    if (kIsWeb) return;
    
    try {
      // Patrón muy agresivo: heavy-pause-heavy-pause-heavy-pause-medium
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      if (_canVibrate()) {
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }

  /// Vibración suave para feedback general
  static Future<void> gentle() async {
    if (!_canVibrate()) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Fallback silencioso si no está disponible
    }
  }
}