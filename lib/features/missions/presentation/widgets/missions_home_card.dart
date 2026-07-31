import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/date_utils.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../domain/entities/mission.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_state.dart';
import 'mission_actions.dart';

/// Tarjeta destacada de Misiones dentro de la página de Hábitos. Da
/// protagonismo a las misiones mostrando las más urgentes con acceso rápido a
/// completarlas y a la pestaña completa. Aparece siempre que Misiones esté
/// activada y haya al menos una pendiente.
class MissionsHomeCard extends StatelessWidget {
  /// Abre la pestaña de Misiones (lo provee MainPage).
  final VoidCallback? onOpenMissions;

  const MissionsHomeCard({super.key, this.onOpenMissions});

  static const int _previewCount = 3;

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
        final pending = state.pending; // ya ordenadas por urgencia
        if (pending.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final preview = pending.take(_previewCount).toList();
        final extra = pending.length - preview.length;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(count: pending.length, onOpenMissions: onOpenMissions),
              ...preview.map(
                (m) => _MissionPreviewRow(
                  mission: m,
                  onToggle:
                      () => toggleMissionWithUndo(
                        context,
                        context.read<MissionBloc>(),
                        m,
                      ),
                  onOpen: onOpenMissions,
                ),
              ),
              if (extra > 0)
                InkWell(
                  onTap: onOpenMissions,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Text(
                      '+ $extra más',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback? onOpenMissions;

  const _Header({required this.count, this.onOpenMissions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.flag, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Misiones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onOpenMissions,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ver todas'),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionPreviewRow extends StatelessWidget {
  final Mission mission;
  final VoidCallback onToggle;
  final VoidCallback? onOpen;

  const _MissionPreviewRow({
    required this.mission,
    required this.onToggle,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    final due = mission.dueDate;
    final overdue =
        due != null && AppDateUtils.getStartOfDay(due).isBefore(today);
    final isToday = due != null && AppDateUtils.getStartOfDay(due) == today;

    return InkWell(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.radio_button_unchecked,
                color: theme.colorScheme.outline,
              ),
              onPressed: onToggle,
              tooltip: 'Completar',
            ),
            Expanded(
              child: Text(
                mission.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (overdue)
              _Chip(
                label: 'Vencida',
                fg: theme.colorScheme.error,
                bg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              )
            else if (isToday)
              _Chip(
                label: 'Hoy',
                fg: theme.colorScheme.primary,
                bg: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _Chip({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
