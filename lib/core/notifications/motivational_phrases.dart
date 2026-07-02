// lib/core/notifications/motivational_phrases.dart
// Frases motivacionales para el recordatorio diario. Rotan según el día del
// año, así cada día aparece una distinta pero estable durante toda la jornada.

class MotivationalPhrases {
  MotivationalPhrases._();

  /// Títulos motivacionales cortos (encabezado de la notificación).
  static const List<String> _titles = [
    '¡Hoy es tu día! 💪',
    'Un pequeño paso cuenta 🌱',
    'Vos podés con esto 🔥',
    'Tu mejor versión te espera ✨',
    'No rompas la racha 🏆',
    'Constancia > motivación 🚀',
    'Sumá un día más 📈',
    'Tus hábitos te llaman 🔔',
    'Hacelo por vos 💙',
    '¡A completar el día! ✅',
    'Cada hábito suma 🌟',
    'El futuro se construye hoy 🧱',
    'Dale, que falta poco 🙌',
    'Disciplina es libertad ⛓️‍💥',
    'Pequeños pasos, grandes cambios 🌊',
  ];

  /// Cierres motivacionales (se anexan al cuerpo con los pendientes).
  static const List<String> _closers = [
    '¡Vos podés! 💪',
    '¡No aflojes! 🔥',
    '¡Un esfuerzo más! 🚀',
    '¡Hoy sí! ✨',
    '¡A por ellos! 🎯',
    '¡Cerrá el día completo! ✅',
    '¡Tu yo del futuro te lo agradece! 🙌',
  ];

  static int _index(DateTime date, int length) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays; // 0..365
    return dayOfYear % length;
  }

  static String titleFor(DateTime date) =>
      _titles[_index(date, _titles.length)];

  static String closerFor(DateTime date) =>
      _closers[_index(date, _closers.length)];
}
