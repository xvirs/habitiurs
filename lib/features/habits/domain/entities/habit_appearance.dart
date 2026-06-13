import 'package:flutter/material.dart';

/// Paleta e iconos curados para personalizar hábitos.
/// Las claves de icono se persisten en BD/Firestore: no renombrar.
class HabitAppearance {
  HabitAppearance._();

  static const List<int> colors = [
    0xFF1565C0, // azul (default, primario de la app)
    0xFF2E7D32, // verde
    0xFFC62828, // rojo
    0xFFEF6C00, // naranja
    0xFF6A1B9A, // violeta
    0xFF00838F, // cian
    0xFFAD1457, // rosa
    0xFF4E342E, // marrón
    0xFF37474F, // gris azulado
    0xFF9E9D24, // oliva
  ];

  static const Map<String, IconData> icons = {
    'check': Icons.check_circle_outline,
    'fitness': Icons.fitness_center,
    'book': Icons.menu_book,
    'water': Icons.water_drop_outlined,
    'sleep': Icons.bedtime_outlined,
    'food': Icons.restaurant_outlined,
    'run': Icons.directions_run,
    'meditate': Icons.self_improvement,
    'study': Icons.school_outlined,
    'work': Icons.work_outline,
    'music': Icons.music_note_outlined,
    'heart': Icons.favorite_outline,
  };

  static IconData iconFor(String key) => icons[key] ?? icons['check']!;
}
