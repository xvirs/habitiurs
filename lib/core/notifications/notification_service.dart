import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar timezone
    tz.initializeTimeZones();

    // Obtener y configurar la zona horaria local del dispositivo
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
      print('✅ [NotificationService] Timezone configurado: $timeZoneName');
    } catch (e) {
      print('❌ [NotificationService] Error configurando timezone: $e');
      // Fallback a UTC o local por defecto si falla
    }

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializar plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos (iOS)
    await _requestPermissions();

    _initialized = true;
  }

  /// Solicita permisos en iOS
  Future<void> _requestPermissions() async {
    final platform =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (platform != null) {
      await platform.requestPermissions(alert: true, badge: true, sound: true);
    }

    final androidPlatform =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlatform != null) {
      await androidPlatform.requestNotificationsPermission();
      await androidPlatform
          .requestExactAlarmsPermission(); // Solicitar permiso de alarmas exactas
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes navegar a una pantalla específica si es necesario
    print('Notificación tocada: ${response.payload}');
  }

  /// Programa la notificación diaria
  Future<void> scheduleDailyReminder({
    required int pendingHabitsCount,
    required List<String> pendingHabitNames,
    int hour = 20, // 8 PM por defecto
    int minute = 0,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Cancelar notificación anterior si existe
    await _notifications.cancel(0);

    // Solo programar si hay hábitos pendientes
    if (pendingHabitsCount == 0) return;

    // Configurar notificación para la hora especificada
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si ya pasó la hora programada hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Crear mensaje personalizado
    final title =
        pendingHabitsCount == 1
            ? '¡Tienes 1 hábito pendiente!'
            : '¡Tienes $pendingHabitsCount hábitos pendientes!';

    final body = _buildNotificationBody(pendingHabitsCount, pendingHabitNames);

    // Detalles de Android
    const androidDetails = AndroidNotificationDetails(
      'daily_habit_reminder_v2', // Cambiado ID para forzar actualización de configuración
      'Recordatorio Diario de Hábitos',
      channelDescription:
          'Notificación diaria para recordar hábitos pendientes',
      importance: Importance.max, // Forzar importancia máxima
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // Detalles de iOS
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Programar notificación
    await _notifications.zonedSchedule(
      0, // ID de la notificación
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repetir diariamente a la misma hora
    );

    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    print('✅ Notificación programada para las $timeStr: $title');
    print(
      '   📅 Fecha exacta programada: $scheduledDate (Zona horaria: ${scheduledDate.location})',
    );
    print('   ⌚ Hora actual referencia: $now');
  }

  /// Construye el cuerpo del mensaje según la cantidad de hábitos
  String _buildNotificationBody(int count, List<String> habitNames) {
    if (count == 0) return '';

    if (count == 1) {
      return 'Aún te falta: "${habitNames.first}". ¡Tú puedes!';
    }

    if (count == 2) {
      return 'Te faltan: "${habitNames[0]}" y "${habitNames[1]}". ¡Vamos!';
    }

    if (count <= 3) {
      return 'Te faltan: ${habitNames.take(count).map((name) => '"$name"').join(', ')}. ¡No te rindas!';
    }

    // Si son más de 3, mostrar solo los primeros 2
    return 'Te faltan: "${habitNames[0]}", "${habitNames[1]}" y ${count - 2} más. ¡Tú puedes completarlos!';
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      await initialize();
    }
    await _notifications.cancelAll();
    print('🔕 [NotificationService] Todas las notificaciones canceladas');
  }

  /// Cancela una notificación específica
  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      await initialize();
    }
    await _notifications.cancel(id);
    print('🔕 [NotificationService] Notificación $id cancelada');
  }

  /// Muestra una notificación inmediata (para testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Canal para notificaciones de prueba',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // ID temporal para testing
      title,
      body,
      details,
    );
  }
}
