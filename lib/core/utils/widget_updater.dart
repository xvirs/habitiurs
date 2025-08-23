import 'package:flutter/services.dart';

class WidgetUpdater {
  static const MethodChannel _channel = MethodChannel(
    'com.example.habitiurs/widget',
  );

  static Future<void> refreshWeeklyHabitsWidget() async {
    try {
      await _channel.invokeMethod('refreshWeeklyHabitsWidget');
    } catch (e) {
      // Puedes loguear el error si lo deseas
    }
  }
}
