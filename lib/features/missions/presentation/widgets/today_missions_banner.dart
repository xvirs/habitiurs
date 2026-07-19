import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/date_utils.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../domain/entities/mission.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_event.dart';
import '../bloc/mission_state.dart';
import 'add_mission_bottom_sheet.dart';
import 'mission_actions.dart';

/// Bloque compacto en la pestaña Hábitos con las misiones pendientes que
/// vencen hoy o ya están vencidas. Solo aparece si Misiones está activada y
/// hay al menos una. Permite completarlas o editarlas sin cambiar de pestaña.
class TodayMissionsBanner extends StatelessWidget {
  const TodayMissionsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final enabled =
        settingsState is SettingsLoaded &&
        settingsState.settings.missionsEnabled;
    if (!enabled) return const SizedBox.shrink();

    return BlocBuilder<MissionBloc, MissionState>(
      builder: (context, state) {
        if (state is! MissionLoaded) return const SizedBox.shrink();

        final today = AppDateUtils.getStartOfDay(DateTime.now());
        final relevant =
            state.missions.where((m) {
                if (m.isDone || m.dueDate == null) return false;
                final due = AppDateUtils.getStartOfDay(m.dueDate!);
                return !due.isAfter(today); // vence hoy o antes
              }).toList()
              ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        if (relevant.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final overdueCount =
            relevant
                .where(
                  (m) => AppDateUtils.getStartOfDay(m.dueDate!).isBefore(today),
                )
                .length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    overdueCount > 0
                        ? 'Misiones para hoy · $overdueCount vencida${overdueCount > 1 ? 's' : ''}'
                        : 'Misiones para hoy',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: relevant.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return _MissionPill(mission: relevant[i], today: today);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissionPill extends StatelessWidget {
  final Mission mission;
  final DateTime today;

  const _MissionPill({required this.mission, required this.today});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = AppDateUtils.getStartOfDay(
      mission.dueDate!,
    ).isBefore(today);
    final accent =
        overdue ? theme.colorScheme.error : theme.colorScheme.primary;
    final bloc = context.read<MissionBloc>();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openEdit(context, bloc),
      child: Container(
        padding: const EdgeInsets.only(left: 4, right: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              iconSize: 18,
              icon: Icon(Icons.radio_button_unchecked, color: accent),
              tooltip: 'Completar',
              onPressed: () => toggleMissionWithUndo(context, bloc, mission),
            ),
            Text(
              mission.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, MissionBloc bloc) {
    AddMissionBottomSheet.show(
      context,
      initial: mission,
      onSubmit: (result) {
        bloc.add(
          EditMission(
            mission.copyWith(
              title: result.title,
              note: result.note,
              clearNote: result.note == null,
              dueDate: result.dueDate,
              clearDueDate: result.dueDate == null,
            ),
          ),
        );
      },
    );
  }
}
