// lib/shared/utils/date_utils.dart
import 'package:intl/intl.dart'; // Asegúrate de que intl esté en tu pubspec.yaml

class AppDateUtils {
  static DateTime getStartOfWeek(DateTime date) {
    // Ajustar para que el Lunes sea el primer día (DateTime.monday = 1)
    // Tu implementación actual es correcta si asume Lunes=1.
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  static List<DateTime> getWeekDates(DateTime startOfWeek) {
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // Nombres de los días de la semana (Lunes a Domingo)
  // Tu lista actual es ['L', 'M', 'M', 'J', 'V', 'S', 'D']
  // Si deseas los nombres completos como en mi sugerencia anterior, cámbialos.
  static List<String> get weekDayNames => ['L', 'M', 'M', 'J', 'V', 'S', 'D']; 

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // Método para auto-skip logic (ya lo tienes, es correcto)
  static bool isPastDate(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dateOnly.isBefore(todayOnly);
  }

  // Obtener primer lunes del mes (ya lo tienes, es correcto)
  static DateTime getFirstMondayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    DateTime monday = firstDay;
    while (monday.weekday != 1) { // 1 = lunes
      monday = monday.add(const Duration(days: 1));
    }
    return monday;
  }

  // Validar si es semana completa del mes (ya lo tienes, es correcto)
  static bool isCompleteWeekInMonth(DateTime weekStart, DateTime monthEnd) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !weekEnd.isAfter(monthEnd);
  }

  // ✅ NUEVO: Método para obtener el inicio del día (hora 00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ✅ NUEVO: Método para obtener el final del día (hora 23:59:59.999)
  static DateTime getEndOfDay(DateTime date) {
    // Añade la precisión de milisegundos para asegurar que abarca todo el día.
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Opcional: Formatea un DateTime a 'yyyy-MM-dd'.
  // Si necesitas esto en otros lugares, puedes añadirlo.
  static String formatToYYYYMMDD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}