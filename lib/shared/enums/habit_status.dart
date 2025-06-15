// lib/shared/enums/habit_status.dart
enum HabitStatus {
  pending('pending', 'Pendiente'),
  completed('completed', 'Completado'),
  skipped('skipped', 'Omitido');

  const HabitStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static HabitStatus fromString(String value) {
    final cleanValue = value.replaceAll('HabitStatus.', '');
    return HabitStatus.values.firstWhere(
      (status) => status.value == cleanValue,
      orElse: () => HabitStatus.pending,
    );
  }

  @override
  String toString() => value;
}