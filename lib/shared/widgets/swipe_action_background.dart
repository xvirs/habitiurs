import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fondos de swipe compartidos entre Hábitos y Misiones, para que el gesto se
/// vea y se sienta igual en toda la app.
///
/// Convención unificada:
/// - swipe a la IZQUIERDA (endToStart) → Eliminar (rojo suave, a la derecha).
/// - swipe a la DERECHA (startToEnd) → Marcar hecho (verde, a la izquierda).
class SwipeActionBackground {
  const SwipeActionBackground._();

  static const double _radius = 10;

  /// Fondo de "Eliminar". Se usa como `secondaryBackground` del Dismissible.
  static Widget delete(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _base(
      color: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      icon: Icons.delete_outline,
      label: 'Eliminar',
      alignEnd: true,
    );
  }

  /// Fondo de "Hecho". Se usa como `background` del Dismissible.
  static Widget complete(BuildContext context) {
    final green = AppColors.completed(context);
    return _base(
      color: green.withValues(alpha: 0.18),
      foreground: green,
      icon: Icons.check_circle_outline,
      label: 'Hecho',
      alignEnd: false,
    );
  }

  static Widget _base({
    required Color color,
    required Color foreground,
    required IconData icon,
    required String label,
    required bool alignEnd,
  }) {
    final children = [
      Icon(icon, color: foreground),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    ];
    return Container(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignEnd ? children.reversed.toList() : children,
      ),
    );
  }
}
