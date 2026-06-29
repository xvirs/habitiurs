// lib/features/habits/presentation/widgets/weekly_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/shared/utils/date_utils.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_appearance.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/habit_entry.dart';
import '../../../../shared/enums/habit_status.dart';
import '../bloc/habit_bloc.dart';
import '../bloc/habit_event.dart';
import 'habit_status_selector_modal.dart';

class WeeklyGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitEntry> weekEntries;
  final DateTime weekStart;
  final bool isLoading;

  const WeeklyGrid({
    super.key,
    required this.habits,
    required this.weekEntries,
    required this.weekStart,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final weekDates = AppDateUtils.getWeekDates(weekStart);

    // Limpiar cache al construir para asegurar datos frescos
    _StatusCell.clearCache();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderSection(weekDates: weekDates),
          _DaysHeader(weekDates: weekDates),
          Expanded(child: _buildBody(weekDates)),
        ],
      ),
    );
  }

  Widget _buildBody(List<DateTime> weekDates) {
    if (isLoading) {
      return const _LoadingState();
    }

    if (habits.isEmpty) {
      return const _EmptyState();
    }

    return _HabitsGrid(
      habits: habits,
      weekDates: weekDates,
      weekEntries: weekEntries,
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final List<DateTime> weekDates;

  const _HeaderSection({required this.weekDates});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _VerticalAccent(color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Icon(Icons.view_week, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vista semanal',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _DateRange(startDay: weekDates.first.day, endDay: weekDates.last.day),
        ],
      ),
    );
  }
}

class _VerticalAccent extends StatelessWidget {
  final Color color;

  const _VerticalAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DateRange extends StatelessWidget {
  final int startDay;
  final int endDay;

  const _DateRange({required this.startDay, required this.endDay});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$startDay - $endDay',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _DaysHeader extends StatelessWidget {
  final List<DateTime> weekDates;

  const _DaysHeader({required this.weekDates});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const SizedBox(width: 28), // Space for habit numbers
          ...weekDates.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            final dayName = AppDateUtils.weekDayNames[index];
            final isToday = AppDateUtils.isToday(date);

            return Expanded(
              child: _DayColumn(
                dayName: dayName,
                dayNumber: date.day,
                isToday: isToday,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final String dayName;
  final int dayNumber;
  final bool isToday;

  const _DayColumn({
    required this.dayName,
    required this.dayNumber,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration:
          isToday
              ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: primaryColor.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
              )
              : null,
      child: Column(
        children: [
          Text(
            dayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              color: isToday ? primaryColor : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: isToday ? primaryColor : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsGrid extends StatelessWidget {
  final List<Habit> habits;
  final List<DateTime> weekDates;
  final List<HabitEntry> weekEntries;

  const _HabitsGrid({
    required this.habits,
    required this.weekDates,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children:
            habits.asMap().entries.map((entry) {
              final index = entry.key;
              final habit = entry.value;
              final isLast = index == habits.length - 1;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                  child: _HabitRow(
                    habit: habit,
                    index: index,
                    weekDates: weekDates,
                    weekEntries: weekEntries,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final int index;
  final List<DateTime> weekDates;
  final List<HabitEntry> weekEntries;

  const _HabitRow({
    required this.habit,
    required this.index,
    required this.weekDates,
    required this.weekEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HabitBadge(habit: habit),
        const SizedBox(width: 4),
        ...weekDates.map(
          (date) => Expanded(
            child: _StatusCell(
              habit: habit,
              date: date,
              weekEntries: weekEntries,
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitBadge extends StatelessWidget {
  final Habit habit;

  const _HabitBadge({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Color(habit.colorValue),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          HabitAppearance.iconFor(habit.iconKey),
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final List<HabitEntry> weekEntries;

  const _StatusCell({
    required this.habit,
    required this.date,
    required this.weekEntries,
  });

  int get habitId => habit.id!;
  String get habitName => habit.name;
  DateTime? get createdAt => habit.createdAt;

  // Cache para mejorar rendimiento
  static final Map<String, HabitEntry?> _entryCache = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Día no programado para este hábito: celda atenuada, sin interacción
    if (!habit.isScheduledOn(date)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 2,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      );
    }

    final entry = _findEntry();
    final status = _getDisplayStatus(entry);
    final isToday = AppDateUtils.isToday(date);
    final isPastDate = AppDateUtils.isPastDate(date);

    return GestureDetector(
      onLongPress: isPastDate ? () => _handleLongPress(context, status) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _getStatusColor(context, status),
          border:
              isToday
                  ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                  : null,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Future<void> _handleLongPress(
    BuildContext context,
    HabitStatus currentStatus,
  ) async {
    if (!context.mounted) return;

    // Mostrar modal de selección (la vibración se hace dentro del modal)
    final selectedStatus = await HabitStatusSelectorModal.show(
      context,
      habitName: habitName,
      currentStatus: currentStatus,
    );

    if (!context.mounted) return;

    if (selectedStatus != null) {
      // Enviar evento al bloc para actualizar el estado
      context.read<HabitBloc>().add(
        UpdatePastHabitEntryEvent(
          habitId: habitId,
          date: date,
          newStatus: selectedStatus,
        ),
      );
    }
  }

  HabitEntry? _findEntry() {
    final cacheKey = '${habitId}_${AppDateUtils.formatToYYYYMMDD(date)}';

    if (_entryCache.containsKey(cacheKey)) {
      return _entryCache[cacheKey];
    }

    // Buscar usando donde por iteración optimizada
    final normalizedDate = AppDateUtils.getStartOfDay(date);
    HabitEntry? foundEntry;

    for (final entry in weekEntries) {
      if (entry.habitId == habitId) {
        final entryDate = AppDateUtils.getStartOfDay(entry.date);
        if (entryDate == normalizedDate) {
          foundEntry = entry;
          break;
        }
      }
    }

    _entryCache[cacheKey] = foundEntry;
    return foundEntry;
  }

  // Método para limpiar cache cuando sea necesario
  static void clearCache() {
    _entryCache.clear();
  }

  HabitStatus _getDisplayStatus(HabitEntry? entry) {
    // Si hay una entrada explícita, usar su estado
    if (entry != null) return entry.status;

    // Si es un día futuro, mostrar como pending
    if (AppDateUtils.isFutureDate(date)) return HabitStatus.pending;

    // LÓGICA DE INCORPORACIÓN: GRIS ANTES DE CREAR
    // Si la fecha es anterior a la creación del hábito, mostrar como pending (Gris),
    // no como skipped (Rojo).
    if (createdAt != null) {
      final normalizedCreatedAt = AppDateUtils.getStartOfDay(createdAt!);
      final normalizedDate = AppDateUtils.getStartOfDay(date);
      if (normalizedDate.isBefore(normalizedCreatedAt)) {
        return HabitStatus.pending;
      }
    }

    // Si es el día actual sin entrada, mostrar como pending
    if (AppDateUtils.isToday(date)) return HabitStatus.pending;

    // Si es un día pasado sin entrada (y posterior a la creación), mostrar como skipped (Rojo)
    if (AppDateUtils.isPastDate(date)) return HabitStatus.skipped;

    return HabitStatus.pending;
  }

  Color _getStatusColor(BuildContext context, HabitStatus status) {
    return switch (status) {
      HabitStatus.completed => AppColors.completed(context),
      HabitStatus.skipped => AppColors.skipped(context),
      HabitStatus.pending =>
        Theme.of(context).colorScheme.surfaceContainerHighest,
    };
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generando tu vista semanal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Calculando tu progreso...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_week,
              size: 40,
              color: theme.colorScheme.outline.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes hábitos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primer hábito para ver el progreso semanal aquí.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
