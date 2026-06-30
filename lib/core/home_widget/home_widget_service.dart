// lib/core/home_widget/home_widget_service.dart
// Puente entre la app y los widgets de pantalla de inicio (Android/iOS).
// Exporta los hábitos de hoy a un almacén compartido que leen los widgets
// nativos, y maneja el marcado desde el widget sin abrir la app (headless).
import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/habits/domain/entities/habit.dart';
import '../../shared/enums/habit_status.dart';
import '../utils/app_logger.dart';

/// Claves compartidas con los widgets nativos.
class _Keys {
  static const todayHabits = 'today_habits'; // JSON: [{id,name,color,icon,status}]
  static const summary = 'today_summary'; // "3/5"
  static const completed = 'today_completed'; // int
  static const total = 'today_total'; // int
}

class HomeWidgetService {
  // App Group para iOS (debe coincidir con el entitlement de la extensión).
  static const String appGroupId = 'group.com.habitiurs.app';

  // Nombres de los providers Android y de los widgets iOS (kind de WidgetKit).
  static const String androidSummaryProvider = 'HabitSummaryWidgetProvider';
  static const String androidListProvider = 'HabitListWidgetProvider';
  static const String iosSummaryWidget = 'HabitiursSummaryWidget';
  static const String iosListWidget = 'HabitiursListWidget';

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

      final items = todayHabits.map((h) {
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
      await HomeWidget.saveWidgetData<String>(_Keys.summary, '$completed/$total');
      await HomeWidget.saveWidgetData<int>(_Keys.completed, completed);
      await HomeWidget.saveWidgetData<int>(_Keys.total, total);

      await _refreshAll();
    } catch (e) {
      appLog('⚠️ [HomeWidget] update falló: $e');
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
    await HomeWidget.saveWidgetData<String>(_Keys.todayHabits, jsonEncode(list));
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
