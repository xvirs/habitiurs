class AppDateUtils {
  static DateTime getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  static List<DateTime> getWeekDates(DateTime startOfWeek) {
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  static List<String> get weekDayNames => ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  // AGREGAR: método para auto-skip logic
  static bool isPastDate(DateTime date) {
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dateOnly.isBefore(todayOnly);
  }

  // AGREGAR: obtener primer lunes del mes
  static DateTime getFirstMondayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    DateTime monday = firstDay;
    while (monday.weekday != 1) { // 1 = lunes
      monday = monday.add(const Duration(days: 1));
    }
    return monday;
  }

  // AGREGAR: validar si es semana completa del mes
  static bool isCompleteWeekInMonth(DateTime weekStart, DateTime monthEnd) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return !weekEnd.isAfter(monthEnd);
  }
}