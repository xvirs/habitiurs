import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habitiurs/core/utils/app_logger.dart';
import 'package:habitiurs/core/notifications/motivational_phrases.dart';

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
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      appLog(
        '✅ [NotificationService] Timezone configurado: ${timezoneInfo.identifier}',
      );
    } catch (e) {
      appLog('❌ [NotificationService] Error configurando timezone: $e');
      // Fallback a UTC si falla
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

    // Crear los canales de Android por adelantado. Es imprescindible para las
    // notificaciones PROGRAMADAS: cuando la alarma dispara, el receiver corre
    // en background y NO crea el canal; si el canal no existe, Android descarta
    // la notificación en silencio. Creándolos acá, quedan listos siempre.
    await _createAndroidChannels();

    _initialized = true;
  }

  /// Crea (idempotente) los canales de notificación en Android.
  Future<void> _createAndroidChannels() async {
    final android =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (android == null) return;

    const daily = AndroidNotificationChannel(
      'daily_habit_reminder_v2',
      'Recordatorio Diario de Hábitos',
      description: 'Notificación diaria para recordar hábitos pendientes',
      importance: Importance.max,
    );
    const perHabit = AndroidNotificationChannel(
      'habit_reminder',
      'Recordatorios de hábitos',
      description: 'Recordatorio individual de cada hábito',
      importance: Importance.high,
    );

    await android.createNotificationChannel(daily);
    await android.createNotificationChannel(perHabit);
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
      // Las alarmas exactas se conceden automáticamente por declarar
      // USE_EXACT_ALARM (Android 13+) y SCHEDULE_EXACT_ALARM (Android 12) en
      // el manifest; no hace falta pedirlas en runtime.
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes navegar a una pantalla específica si es necesario
    appLog('Notificación tocada: ${response.payload}');
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

    // Título motivacional (rota por día) + cuerpo con los pendientes de hoy.
    final today = DateTime.now();
    final title = MotivationalPhrases.titleFor(today);
    final body = _buildNotificationBody(
      pendingHabitsCount,
      pendingHabitNames,
      today,
    );

    // Detalles de Android
    const androidDetails = AndroidNotificationDetails(
      'daily_habit_reminder_v2', // Cambiado ID para forzar actualización de configuración
      'Recordatorio Diario de Hábitos',
      channelDescription:
          'Notificación diaria para recordar hábitos pendientes',
      importance: Importance.max, // Forzar importancia máxima
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''), // muestra el texto completo
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

    // Alarma exacta: el recordatorio llega a la hora puesta aunque el equipo
    // esté en reposo (requiere SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM en el manifest).
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
    appLog('✅ Notificación programada para las $timeStr: $title');
    appLog(
      '   📅 Fecha exacta programada: $scheduledDate (Zona horaria: ${scheduledDate.location})',
    );
    appLog('   ⌚ Hora actual referencia: $now');
  }

  /// Construye el cuerpo del mensaje: hábitos pendientes + cierre motivacional.
  String _buildNotificationBody(
    int count,
    List<String> habitNames,
    DateTime date,
  ) {
    if (count == 0) return '';

    final closer = MotivationalPhrases.closerFor(date);
    final String pending;

    if (count == 1) {
      pending = 'Te falta: "${habitNames.first}".';
    } else if (count == 2) {
      pending = 'Te faltan: "${habitNames[0]}" y "${habitNames[1]}".';
    } else if (count == 3) {
      pending =
          'Te faltan: "${habitNames[0]}", "${habitNames[1]}" y "${habitNames[2]}".';
    } else {
      pending =
          'Te faltan "${habitNames[0]}", "${habitNames[1]}" y ${count - 2} más.';
    }

    return '$pending $closer';
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      await initialize();
    }
    await _notifications.cancelAll();
    appLog('🔕 [NotificationService] Todas las notificaciones canceladas');
  }

  /// Cancela una notificación específica
  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      await initialize();
    }
    await _notifications.cancel(id);
    appLog('🔕 [NotificationService] Notificación $id cancelada');
  }

  // ─── Recordatorios por hábito ──────────────────────────────────────────
  // Ids reservados: 1000 + habitId * 10 + weekday (1=lun … 7=dom).
  // El id 0 sigue siendo el resumen diario global.

  static int _habitReminderId(int habitId, int weekday) =>
      1000 + habitId * 10 + weekday;

  /// Programa el recordatorio propio de un hábito en sus días programados.
  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required String reminderTime, // 'HH:mm'
    required List<int> weekdays,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await cancelHabitReminder(habitId);

    final parts = reminderTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    const androidDetails = AndroidNotificationDetails(
      'habit_reminder',
      'Recordatorios de hábitos',
      channelDescription: 'Recordatorio individual de cada hábito',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    for (final weekday in weekdays) {
      final scheduledDate = _nextInstanceOfWeekdayTime(weekday, hour, minute);
      await _notifications.zonedSchedule(
        _habitReminderId(habitId, weekday),
        habitName,
        'Es momento de cumplir tu hábito. ¡Tú puedes!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
    appLog(
      '⏰ [NotificationService] Recordatorio de hábito $habitId programado '
      '($reminderTime, días: $weekdays)',
    );
  }

  /// Cancela todos los recordatorios propios de un hábito.
  Future<void> cancelHabitReminder(int habitId) async {
    if (!_initialized) {
      await initialize();
    }
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _notifications.cancel(_habitReminderId(habitId, weekday));
    }
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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
