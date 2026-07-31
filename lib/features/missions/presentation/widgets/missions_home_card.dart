import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/date_utils.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_state.dart';

/// Tira compacta de Misiones en la página de Hábitos. Un solo renglón, para
/// que las misiones se noten sin robar espacio: cuenta de pendientes (y
/// vencidas si las hay) y toque para abrir la pestaña de Misiones. Aparece
/// siempre que Misiones esté activada y haya al menos una pendiente.
class MissionsHomeCard extends StatelessWidget {
  /// Abre la pestaña de Misiones (lo provee MainPage).
  final VoidCallback? onOpenMissions;

  const MissionsHomeCard({super.key, this.onOpenMissions});

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
        final pending = state.pending;
        if (pending.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final today = AppDateUtils.getStartOfDay(DateTime.now());
        final overdue =
            pending
                .where(
                  (m) =>
                      m.dueDate != null &&
                      AppDateUtils.getStartOfDay(m.dueDate!).isBefore(today),
                )
                .length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Material(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onOpenMissions,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text:
                                  '${pending.length} '
                                  '${pending.length == 1 ? "misión pendiente" : "misiones pendientes"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (overdue > 0)
                              TextSpan(
                                text:
                                    '  ·  $overdue vencida${overdue > 1 ? "s" : ""}',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'Ver',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
