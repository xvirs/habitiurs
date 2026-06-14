import 'package:flutter/widgets.dart';

/// Utilidades de diseño adaptativo (teléfono vs. pantalla ancha / Fold).
class Responsive {
  Responsive._();

  /// Ancho lógico a partir del cual se considera pantalla "ancha"
  /// (tablet o Samsung Fold desplegado). Por debajo: teléfono normal.
  static const double wideBreakpoint = 600;

  /// Ancho de contenido legible para una sola columna en pantallas anchas
  /// (evita que las tarjetas y filas se estiren demasiado).
  static const double readableMaxWidth = 640;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;
}

/// Limita el ancho del contenido y lo centra en pantallas anchas.
/// En teléfono ocupa todo el ancho como siempre (la restricción no aplica).
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = Responsive.readableMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
