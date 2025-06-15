// lib/features/habits/presentation/widgets/habit_status_icon.dart - MEJORADO
import 'package:flutter/material.dart';
import '../../../../shared/enums/habit_status.dart';

class HabitStatusIcon extends StatelessWidget {
  final HabitStatus status;
  final double size;

  const HabitStatusIcon({
    super.key,
    required this.status,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case HabitStatus.completed:
        return Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: size,
        );
      case HabitStatus.skipped:
        return Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: size,
        );
      case HabitStatus.pending:
        return Icon(
          Icons.add_rounded,
          color: Colors.grey[600],
          size: size,
        );
    }
  }
}

class HabitStatusColor {
  static Color getColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[500]!; // Verde más suave
      case HabitStatus.skipped:
        return Colors.red[400]!; // Rojo más suave
      case HabitStatus.pending:
        return Colors.grey[200]!;
    }
  }

  // Colores adicionales para diferentes contextos
  static Color getTextColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[700]!;
      case HabitStatus.skipped:
        return Colors.red[600]!;
      case HabitStatus.pending:
        return Colors.grey[800]!;
    }
  }

  static Color getBackgroundColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green[50]!;
      case HabitStatus.skipped:
        return Colors.red[50]!;
      case HabitStatus.pending:
        return Colors.grey[50]!;
    }
  }
}