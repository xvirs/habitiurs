// lib/shared/enums/habit_status.dart
enum HabitStatus {
  pending, // 0 - Sin decidir (gris con +)
  completed, // 1 - Realizado (verde con ✓)
  skipped, // 2 - No realizado conscientemente (rojo con ✗)
}

extension HabitStatusExtension on HabitStatus {
  String get displayName {
    switch (this) {
      case HabitStatus.pending:
        return 'Pendiente';
      case HabitStatus.completed:
        return 'Completado';
      case HabitStatus.skipped:
        return 'Omitido';
    }
  }

  String get emoji {
    switch (this) {
      case HabitStatus.pending:
        return '⏳';
      case HabitStatus.completed:
        return '✅';
      case HabitStatus.skipped:
        return '❌';
    }
  }
}
