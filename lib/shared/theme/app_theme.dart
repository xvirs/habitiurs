// lib/shared/theme/app_theme.dart - TEMA (claro y oscuro)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const Color _seed = Colors.blue;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// Azul de marca para oscuro: sólido y un poco más oscuro (no el pastel
  /// que M3 genera en modo oscuro).
  static const Color _brandBlue = Color(0xFF1976D2); // Blue 700

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    var scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

    // En oscuro, M3 aclara el primario (queda celeste/fluorescente). Lo
    // forzamos al azul de marca para que se vea igual de sólido que en claro.
    if (isDark) {
      scheme = scheme.copyWith(primary: _brandBlue, onPrimary: Colors.white);
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        // Iconos de la barra de estado: oscuros en claro, claros en oscuro.
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Colores semánticos de hábitos/estadísticas que se adaptan al brillo.
/// Verde = completado, rojo = no realizado, naranja = advertencia/pendiente.
class AppColors {
  AppColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color completed(BuildContext context) =>
      _isDark(context) ? const Color(0xFF66BB6A) : const Color(0xFF43A047);

  static Color skipped(BuildContext context) =>
      _isDark(context) ? const Color(0xFFEF5350) : const Color(0xFFE53935);

  static Color warning(BuildContext context) =>
      _isDark(context) ? const Color(0xFFFFA726) : const Color(0xFFFB8C00);
}
