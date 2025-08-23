// lib/features/habits/presentation/widgets/habit_status_styles.dart
import 'package:flutter/material.dart';
import '../../../../shared/enums/habit_status.dart';

/// Clase utilitaria para manejo de estilos de estado de hábitos
/// Centraliza colores, iconos y estilos para mejor mantenimiento
class HabitStatusStyles {
  HabitStatusStyles._(); // Constructor privado para clase estática

  // Colores de fondo
  static const Map<HabitStatus, Color> _backgroundColors = {
    HabitStatus.completed: Color(0xFF4CAF50), // Colors.green[500]
    HabitStatus.pending: Color(0xFFF5F5F5),   // Colors.grey[100]
    HabitStatus.skipped: Color(0xFFEF5350),   // Colors.red[400]
  };

  // Colores de borde
  static const Map<HabitStatus, Color> _borderColors = {
    HabitStatus.completed: Color(0xFF43A047), // Colors.green[600]
    HabitStatus.pending: Color(0xFFBDBDBD),   // Colors.grey[400]
    HabitStatus.skipped: Color(0xFFE53935),   // Colors.red[500]
  };

  // Colores de borde para tiles (más suaves)
  static final Map<HabitStatus, Color> _tileBorderColors = {
    HabitStatus.completed: Colors.green.withOpacity(0.3),
    HabitStatus.pending: Colors.grey.withOpacity(0.3),
    HabitStatus.skipped: Colors.red.withOpacity(0.3),
  };

  // Iconos por estado
  static const Map<HabitStatus, IconData> _icons = {
    HabitStatus.completed: Icons.check,
    HabitStatus.pending: Icons.add,
    HabitStatus.skipped: Icons.close,
  };

  // Colores de icono
  static final Map<HabitStatus, Color> _iconColors = {
    HabitStatus.completed: Colors.white,
    HabitStatus.pending: Colors.grey[600]!,
    HabitStatus.skipped: Colors.white,
  };

  // Getters públicos
  static Color getBackgroundColor(HabitStatus status) =>
      _backgroundColors[status]!;

  static Color getBorderColor(HabitStatus status) =>
      _borderColors[status]!;

  static Color getTileBorderColor(HabitStatus status) =>
      _tileBorderColors[status]!;

  static IconData getIcon(HabitStatus status) =>
      _icons[status]!;

  static Color getIconColor(HabitStatus status) =>
      _iconColors[status]!;

  /// Widget de icono pre-configurado
  static Widget buildStatusIcon(HabitStatus status, {double size = 18}) {
    return Icon(
      getIcon(status),
      color: getIconColor(status),
      size: size,
    );
  }

  /// Decoración de toggle pre-configurada
  static BoxDecoration buildToggleDecoration(HabitStatus status) {
    return BoxDecoration(
      color: getBackgroundColor(status),
      border: Border.all(
        color: getBorderColor(status),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(6),
    );
  }

  /// Decoración de tile pre-configurada
  static BoxDecoration buildTileDecoration(HabitStatus status) {
    return BoxDecoration(
      border: Border.all(
        color: getTileBorderColor(status),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
      color: status == HabitStatus.completed 
          ? Colors.green.withOpacity(0.05)
          : null,
    );
  }

  /// Estilo de texto para nombre de hábito
  static TextStyle buildHabitNameStyle(HabitStatus status, TextStyle baseStyle) {
    return baseStyle.copyWith(
      decoration: status == HabitStatus.completed
          ? TextDecoration.lineThrough
          : null,
      color: status == HabitStatus.completed
          ? Colors.grey[600]
          : null,
      fontWeight: FontWeight.w500,
    );
  }
}