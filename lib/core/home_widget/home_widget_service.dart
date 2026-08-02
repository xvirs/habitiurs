// lib/core/home_widget/home_widget_service.dart
// Puente entre la app y los widgets de pantalla de inicio (Android/iOS).
// Exporta los hábitos de hoy a un almacén compartido que leen los widgets
// nativos, y maneja el marcado desde el widget sin abrir la app (headless).
import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/habits/domain/entities/habit.dart';
import '../../features/missions/domain/entities/mission.dart';
import '../../features/statistics/domain/entities/statistics.dart';
import '../../shared/enums/habit_status.dart';
import '../../shared/utils/date_utils.dart';
import '../di/injection_container.dart';
import '../utils/app_logger.dart';

/// Claves compartidas con los widgets nativos.
class _Keys {
  // Hábitos de hoy (widgets "Hoy" Resumen + Lista).
  static const todayHabits =
      'today_habits'; // JSON: [{id,name,color,icon,status}]
  static const summary = 'today_summary'; // "3/5"
  static const completed = 'today_completed'; // int
  static const total = 'today_total'; // int

  // Racha (widget "No rompas la cadena").
  static const streakCurrent = 'streak_current'; // int
  static const streakBest = 'streak_best'; // int

  // Constancia (heatmap). JSON: {"weeks":15,"levels":[-1|0..3,...]}
  static const heatData = 'heat_data';

  // Misiones (widget "Pendientes").
  static const missionItems = 'mission_items'; // JSON: [{title,urgency,due}]
  static const missionPending = 'mission_pending'; // int
}

class HomeWidgetService {
  // App Group para iOS (debe coincidir con el entitlement de la extensión).
  static const String appGroupId = 'group.com.habitiurs.app';

  // Nombres de los providers Android y de los widgets iOS (kind de WidgetKit).
  static const String androidSummaryProvider = 'HabitSummaryWidgetProvider';
  static const String androidListProvider = 'HabitListWidgetProvider';
  static const String androidStreakProvider = 'StreakWidgetProvider';
  static const String androidHeatmapProvider = 'HeatmapWidgetProvider';
  static const String androidMissionsProvider = 'MissionsWidgetProvider';
  static const String iosSummaryWidget = 'HabitiursSummaryWidget';
  static const String iosListWidget = 'HabitiursListWidget';
  static const String iosStreakWidget = 'HabitiursStreakWidget';
  static const String iosHeatmapWidget = 'HabitiursHeatmapWidget';
  static const String iosMissionsWidget = 'HabitiursMissionsWidget';

  /// Llamar una vez al inicializar la app.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
    } catch (e) {
      appLog('⚠️ [HomeWidget] init falló: $e');
    }
  }

  /// Exporta los hábitos de hoy y refresca los widgets.
  static Future<void> update(
    List<Habit> habits,
    Map<int, HabitStatus> todayStatus,
  ) async {
    try {
      final now = DateTime.now();
      final todayHabits =
          habits
              .where((h) => h.isActive && h.id != null && h.isScheduledOn(now))
              .toList();

      final items =
          todayHabits.map((h) {
            final status = todayStatus[h.id] ?? HabitStatus.pending;
            return {
              'id': h.id,
              'name': h.name,
              'color': h.colorValue,
              'icon': h.iconKey,
              'status': status.index, // 0=pending 1=completed 2=skipped
            };
          }).toList();

      final completed = items.where((e) => e['status'] == 1).length;
      final total = items.length;

      await HomeWidget.saveWidgetData<String>(
        _Keys.todayHabits,
        jsonEncode(items),
      );
      await HomeWidget.saveWidgetData<String>(
        _Keys.summary,
        '$completed/$total',
      );
      await HomeWidget.saveWidgetData<int>(_Keys.completed, completed);
      await HomeWidget.saveWidgetData<int>(_Keys.total, total);

      await _refreshAll();
    } catch (e) {
      appLog('⚠️ [HomeWidget] update falló: $e');
    }
  }

  /// iOS: aplica a la BD los toggles hechos desde el widget (que se guardaron en
  /// `pending_toggles` del App Group porque la extensión no puede tocar la BD de
  /// la app). Devuelve true si aplicó algún cambio. Es no-op en Android.
  static Future<bool> applyPendingIosToggles() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>('pending_toggles');
      if (raw == null || raw.isEmpty || raw == '{}') return false;
      final Map<String, dynamic> pending =
          jsonDecode(raw) as Map<String, dynamic>;
      if (pending.isEmpty) return false;

      // Misma base que usa la app. No la cerramos (handle compartido).
      final dbPath = p.join(await getDatabasesPath(), 'habitiurs.db');
      final db = await openDatabase(dbPath);
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final nowIso = DateTime.now().toIso8601String();

      for (final entry in pending.entries) {
        final id = int.tryParse(entry.key);
        final status = (entry.value as num?)?.toInt();
        if (id == null || status == null) continue;
        final existing = await db.query(
          'habit_entries',
          where: 'habit_id = ? AND date = ?',
          whereArgs: [id, todayStr],
        );
        if (existing.isNotEmpty) {
          await db.update(
            'habit_entries',
            {'status': status, 'last_modified': nowIso},
            where: 'habit_id = ? AND date = ?',
            whereArgs: [id, todayStr],
          );
        } else {
          await db.insert('habit_entries', {
            'habit_id': id,
            'date': todayStr,
            'status': status,
            'last_modified': nowIso,
          });
        }
      }

      await HomeWidget.saveWidgetData<String>('pending_toggles', '{}');
      appLog(
        '✅ [HomeWidget] ${pending.length} toggle(s) de iOS aplicados a la BD',
      );
      return true;
    } catch (e) {
      appLog('⚠️ [HomeWidget] reconciliación iOS falló: $e');
      return false;
    }
  }

  static Future<void> _refreshAll() async {
    await HomeWidget.updateWidget(
      androidName: androidSummaryProvider,
      iOSName: iosSummaryWidget,
    );
    await HomeWidget.updateWidget(
      androidName: androidListProvider,
      iOSName: iosListWidget,
    );
  }

  /// Exporta racha, heatmap de constancia y misiones urgentes, y refresca
  /// esos widgets. Se alimenta de los repositorios (no depende de un BLoC), así
  /// funciona tanto al iniciar la app como tras cambios en hábitos/misiones.
  static Future<void> refreshDerived() async {
    try {
      final ic = InjectionContainer();

      // --- Rachas + heatmap desde la actividad diaria ---
      final daily = await ic.statisticsRepository.getDailyActivity();
      final insights = ActivityInsights.fromDaily(daily);
      await HomeWidget.saveWidgetData<int>(
        _Keys.streakCurrent,
        insights.currentStreak,
      );
      await HomeWidget.saveWidgetData<int>(
        _Keys.streakBest,
        insights.bestStreak,
      );
      await HomeWidget.saveWidgetData<String>(
        _Keys.heatData,
        jsonEncode(_buildHeat(daily, weeks: 15)),
      );

      // --- Misiones urgentes ---
      final missions = await ic.missionRepository.getAllMissions();
      final pending = missions.where((m) => !m.isDone).toList();
      await HomeWidget.saveWidgetData<String>(
        _Keys.missionItems,
        jsonEncode(_urgentMissionItems(pending, max: 6)),
      );
      await HomeWidget.saveWidgetData<int>(_Keys.missionPending, pending.length);

      await HomeWidget.updateWidget(
        androidName: androidStreakProvider,
        iOSName: iosStreakWidget,
      );
      await HomeWidget.updateWidget(
        androidName: androidHeatmapProvider,
        iOSName: iosHeatmapWidget,
      );
      await HomeWidget.updateWidget(
        androidName: androidMissionsProvider,
        iOSName: iosMissionsWidget,
      );
    } catch (e) {
      appLog('⚠️ [HomeWidget] refreshDerived falló: $e');
    }
  }

  /// Niveles del heatmap alineados por día de la semana (lunes→domingo),
  /// terminando en la semana actual. `-1` marca días futuros (celdas vacías).
  static Map<String, dynamic> _buildHeat(
    List<DailyActivity> daily, {
    required int weeks,
  }) {
    DateTime key(DateTime d) => DateTime(d.year, d.month, d.day);
    final byDay = <DateTime, DailyActivity>{
      for (final a in daily) key(a.date): a,
    };
    final today = key(DateTime.now());
    // Lunes de la primera semana de la ventana.
    final startMonday = today
        .subtract(Duration(days: today.weekday - 1))
        .subtract(Duration(days: 7 * (weeks - 1)));
    final levels = <int>[];
    for (var i = 0; i < weeks * 7; i++) {
      final d = startMonday.add(Duration(days: i));
      levels.add(d.isAfter(today) ? -1 : (byDay[d]?.level ?? 0));
    }
    return {'weeks': weeks, 'levels': levels};
  }

  /// Misiones pendientes ordenadas por urgencia (vencidas→hoy→próximas→sin
  /// fecha) y recortadas a [max]. Replica la lógica de la pestaña Misiones.
  static List<Map<String, dynamic>> _urgentMissionItems(
    List<Mission> pending, {
    required int max,
  }) {
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    int urgency(Mission m) {
      final due = m.dueDate;
      if (due == null) return 3; // sin fecha
      final d = AppDateUtils.getStartOfDay(due);
      if (d.isBefore(today)) return 0; // vencida
      if (d == today) return 1; // hoy
      return 2; // próxima
    }

    final sorted = [...pending]..sort((a, b) {
      final ua = urgency(a), ub = urgency(b);
      if (ua != ub) return ua.compareTo(ub);
      final da = a.dueDate, db = b.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return sorted
        .take(max)
        .map(
          (m) => {
            'title': m.title,
            'urgency': urgency(m),
            'due': _dueLabel(m.dueDate, today),
          },
        )
        .toList();
  }

  static String _dueLabel(DateTime? due, DateTime today) {
    if (due == null) return '';
    final d = AppDateUtils.getStartOfDay(due);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    if (diff < -1) return 'hace ${-diff} d';
    if (diff <= 7) return 'en $diff d';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

/// Callback que corre en un isolate de fondo cuando se toca el check de un
/// hábito en el widget (sin abrir la app). URI esperada: habitiurs://toggle?id=5
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'toggle') return;
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  if (id == null) return;

  try {
    // 1. Leer el estado actual desde el JSON ya cacheado del widget.
    final raw = await HomeWidget.getWidgetData<String>(_Keys.todayHabits);
    if (raw == null) return;
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final idx = list.indexWhere((e) => e['id'] == id);
    if (idx == -1) return;

    final current = list[idx]['status'] as int; // 0/1/2
    final next = current == 1 ? 0 : 1; // completed→pending, resto→completed

    // 2. Persistir en sqflite (mismo archivo que usa la app).
    // IMPORTANTE: no cerramos la base. sqflite comparte el handle nativo por
    // ruta; cerrarlo acá cerraría la conexión que usa la app en primer plano
    // (causa el error "database_closed"). El isolate de fondo se destruye solo.
    final dbPath = p.join(await getDatabasesPath(), 'habitiurs.db');
    final db = await openDatabase(dbPath);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final nowIso = DateTime.now().toIso8601String();
    final existing = await db.query(
      'habit_entries',
      where: 'habit_id = ? AND date = ?',
      whereArgs: [id, todayStr],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'habit_entries',
        {'status': next, 'last_modified': nowIso},
        where: 'habit_id = ? AND date = ?',
        whereArgs: [id, todayStr],
      );
    } else {
      await db.insert('habit_entries', {
        'habit_id': id,
        'date': todayStr,
        'status': next,
        'last_modified': nowIso,
      });
    }

    // 3. Actualizar el JSON del widget y refrescar.
    list[idx]['status'] = next;
    final completed = list.where((e) => e['status'] == 1).length;
    await HomeWidget.saveWidgetData<String>(
      _Keys.todayHabits,
      jsonEncode(list),
    );
    await HomeWidget.saveWidgetData<String>(
      _Keys.summary,
      '$completed/${list.length}',
    );
    await HomeWidget.saveWidgetData<int>(_Keys.completed, completed);
    await HomeWidget.saveWidgetData<int>(_Keys.total, list.length);

    await HomeWidget.updateWidget(
      androidName: HomeWidgetService.androidSummaryProvider,
      iOSName: HomeWidgetService.iosSummaryWidget,
    );
    await HomeWidget.updateWidget(
      androidName: HomeWidgetService.androidListProvider,
      iOSName: HomeWidgetService.iosListWidget,
    );
  } catch (e) {
    appLog('⚠️ [HomeWidget] toggle headless falló: $e');
  }
}
