// lib/features/habits/domain/services/habit_validation_service.dart
import '../entities/habit.dart';
import '../entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../../shared/utils/date_utils.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class HabitValidationService {
  /// Valida que un hábito tenga datos consistentes
  static bool isValidHabit(Habit habit) {
    if (habit.name.trim().isEmpty) return false;
    if (habit.createdAt.isAfter(DateTime.now())) return false;
    return true;
  }

  /// Valida que una entrada de hábito tenga datos consistentes
  static bool isValidHabitEntry(HabitEntry entry) {
    if (entry.habitId <= 0) return false;

    // La fecha no puede estar más de 7 días en el futuro
    final maxFutureDate = DateTime.now().add(const Duration(days: 7));
    if (entry.date.isAfter(maxFutureDate)) return false;

    return true;
  }

  /// Filtra y valida la lista de hábitos
  static List<Habit> validateHabits(List<Habit> habits) {
    return habits
        .where(isValidHabit)
        .where((habit) => habit.isActive)
        .toList();
  }

  /// Valida consistencia entre hábitos y entradas para una semana específica
  static ValidationResult validateWeekData(
    List<Habit> habits,
    List<HabitEntry> weekEntries,
    DateTime weekStart,
  ) {
    final issues = <String>[];
    final warnings = <String>[];

    // Validar hábitos
    final validHabits = validateHabits(habits);
    if (validHabits.length != habits.length) {
      issues.add('Se encontraron ${habits.length - validHabits.length} hábitos inválidos');
    }

    // Validar entradas. Solo cuentan como "inválidas" las que tienen datos
    // corruptos (id <= 0, fecha demasiado futura). Las entradas que pertenecen
    // a un hábito archivado/inactivo NO son inválidas: simplemente se excluyen
    // de la vista de la semana sin romper la carga.
    final structurallyValid = weekEntries.where(isValidHabitEntry).toList();
    final corruptCount = weekEntries.length - structurallyValid.length;
    if (corruptCount > 0) {
      issues.add('Se encontraron $corruptCount entradas inválidas');
    }

    final habitIds = validHabits.map((h) => h.id!).toSet();
    final validEntries = structurallyValid
        .where((entry) => habitIds.contains(entry.habitId))
        .toList();

    // Entradas excluidas por pertenecer a un hábito archivado/inactivo: solo
    // informativo, no es un error.
    final orphanCount = structurallyValid.length - validEntries.length;
    if (orphanCount > 0) {
      warnings.add('Se excluyeron $orphanCount entradas de hábitos archivados');
    }

    // Verificar duplicados por fecha y hábito
    final duplicateCheck = <String>{};
    final duplicates = <HabitEntry>[];
    for (final entry in validEntries) {
      final key = '${entry.habitId}_${AppDateUtils.formatToYYYYMMDD(entry.date)}';
      if (duplicateCheck.contains(key)) {
        duplicates.add(entry);
      } else {
        duplicateCheck.add(key);
      }
    }
    if (duplicates.isNotEmpty) {
      issues.add('Se encontraron ${duplicates.length} entradas duplicadas');
    }

    return ValidationResult(
      isValid: issues.isEmpty,
      validHabits: validHabits,
      validEntries: validEntries.where((entry) => !duplicates.contains(entry)).toList(),
      issues: issues,
      warnings: warnings,
    );
  }

  /// Auto-genera entradas faltantes para días pasados
  static List<HabitEntry> generateMissingEntries(
    List<Habit> habits,
    List<HabitEntry> existingEntries,
    DateTime weekStart,
  ) {
    final missingEntries = <HabitEntry>[];
    final weekDates = AppDateUtils.getWeekDates(weekStart);
    final today = AppDateUtils.getStartOfDay(DateTime.now());

    // Crear un mapa de entradas existentes para búsqueda rápida
    final existingEntriesMap = <String, HabitEntry>{};
    for (final entry in existingEntries) {
      final key = '${entry.habitId}_${AppDateUtils.formatToYYYYMMDD(entry.date)}';
      existingEntriesMap[key] = entry;
    }

    for (final habit in habits) {
      final habitCreationDate = AppDateUtils.getStartOfDay(habit.createdAt);

      for (final date in weekDates) {
        final normalizedDate = AppDateUtils.getStartOfDay(date);
        final key = '${habit.id!}_${AppDateUtils.formatToYYYYMMDD(normalizedDate)}';

        // Skip si ya existe una entrada
        if (existingEntriesMap.containsKey(key)) {
          // Log para debugging: entrada ya existe
          appLog('✓ [ValidationService] Entrada existente: ${habit.name} en ${AppDateUtils.formatToYYYYMMDD(normalizedDate)}');
          continue;
        }

        // Skip si la fecha es antes de que se creara el hábito
        if (normalizedDate.isBefore(habitCreationDate)) continue;

        // Skip si es día futuro
        if (normalizedDate.isAfter(today)) continue;

        // Skip si el hábito no está programado para este día de la semana
        if (!habit.isScheduledOn(normalizedDate)) continue;

        // Para días pasados sin entrada, crear entrada con estado skipped
        if (normalizedDate.isBefore(today)) {
          appLog('⚠️ [ValidationService] Generando entrada SKIPPED: ${habit.name} en ${AppDateUtils.formatToYYYYMMDD(normalizedDate)}');
          missingEntries.add(HabitEntry(
            habitId: habit.id!,
            date: normalizedDate,
            status: HabitStatus.skipped,
          ));
        }
      }
    }

    return missingEntries;
  }
}

class ValidationResult {
  final bool isValid;
  final List<Habit> validHabits;
  final List<HabitEntry> validEntries;
  final List<String> issues;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.validHabits,
    required this.validEntries,
    required this.issues,
    required this.warnings,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, habits: ${validHabits.length}, entries: ${validEntries.length}, issues: ${issues.length}, warnings: ${warnings.length})';
  }
}