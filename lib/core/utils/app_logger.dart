import 'package:flutter/foundation.dart';

/// Log de desarrollo: visible solo en builds de debug.
/// En release no imprime nada (evita ruido y fugas de información en logcat).
void appLog(Object? message) {
  if (kDebugMode) {
    debugPrint('$message');
  }
}
