// lib/features/habits/presentation/widgets/habit_status_styles.dart
import 'package:flutter/material.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/theme/app_theme.dart';

/// Clase utilitaria para manejo de estilos de estado de hábitos.
/// Centraliza colores, iconos y estilos; se adapta a tema claro/oscuro.
class HabitStatusStyles {
  HabitStatusStyles._();

  // Iconos por estado
  static const Map<HabitStatus, IconData> _icons = {
    HabitStatus.completed: Icons.check,
    HabitStatus.pending: Icons.add,
    HabitStatus.skipped: Icons.close,
  };

  static IconData getIcon(HabitStatus status) => _icons[status]!;

  /// Color de fondo del toggle según estado y brillo del tema.
  static Color getBackgroundColor(BuildContext context, HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return AppColors.completed(context);
      case HabitStatus.skipped:
        return AppColors.skipped(context);
      case HabitStatus.pending:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  /// Color de borde del toggle.
  static Color getBorderColor(BuildContext context, HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return AppColors.completed(context);
      case HabitStatus.skipped:
        return AppColors.skipped(context);
      case HabitStatus.pending:
        return Theme.of(context).colorScheme.outline;
    }
  }

  /// Color del icono dentro del toggle.
  static Color getIconColor(BuildContext context, HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
      case HabitStatus.skipped:
        return Colors.white;
      case HabitStatus.pending:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  /// Borde suave para las filas (tiles).
  static Color getTileBorderColor(BuildContext context, HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return AppColors.completed(context).withValues(alpha: 0.4);
      case HabitStatus.skipped:
        return AppColors.skipped(context).withValues(alpha: 0.4);
      case HabitStatus.pending:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }

  /// Widget de icono pre-configurado.
  static Widget buildStatusIcon(
    BuildContext context,
    HabitStatus status, {
    double size = 18,
  }) {
    return Icon(
      getIcon(status),
      color: getIconColor(context, status),
      size: size,
    );
  }

  /// Decoración de toggle pre-configurada.
  static BoxDecoration buildToggleDecoration(
    BuildContext context,
    HabitStatus status,
  ) {
    return BoxDecoration(
      color: getBackgroundColor(context, status),
      border: Border.all(color: getBorderColor(context, status), width: 2),
      borderRadius: BorderRadius.circular(6),
    );
  }

  /// Decoración de tile (fila) pre-configurada.
  static BoxDecoration buildTileDecoration(
    BuildContext context,
    HabitStatus status,
  ) {
    return BoxDecoration(
      border: Border.all(color: getTileBorderColor(context, status), width: 1),
      borderRadius: BorderRadius.circular(8),
      color:
          status == HabitStatus.completed
              ? AppColors.completed(context).withValues(alpha: 0.06)
              : null,
    );
  }

  /// Estilo de texto para el nombre de hábito.
  static TextStyle buildHabitNameStyle(
    BuildContext context,
    HabitStatus status,
    TextStyle baseStyle,
  ) {
    final isCompleted = status == HabitStatus.completed;
    return baseStyle.copyWith(
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      color:
          isCompleted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
      fontWeight: FontWeight.w500,
    );
  }
}
