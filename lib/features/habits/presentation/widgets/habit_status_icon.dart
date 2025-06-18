// lib/features/habits/presentation/widgets/habit_status_icon.dart - DISEÑO MINIMALISTA
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
          Icons.check,
          color: Colors.white,
          size: size,
        );
      case HabitStatus.skipped:
        return Icon(
          Icons.close,
          color: Colors.white,
          size: size,
        );
      case HabitStatus.pending:
        return Icon(
          Icons.circle_outlined,
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
        return Colors.green;
      case HabitStatus.skipped:
        return Colors.red[400]!;
      case HabitStatus.pending:
        return Colors.transparent;
    }
  }

  static Color getBorderColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Colors.green;
      case HabitStatus.skipped:
        return Colors.red[400]!;
      case HabitStatus.pending:
        return Colors.grey[400]!;
    }
  }

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
}