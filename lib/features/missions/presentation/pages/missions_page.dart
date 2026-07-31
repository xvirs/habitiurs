import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../../shared/widgets/swipe_action_background.dart';
import '../../domain/entities/mission.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_event.dart';
import '../bloc/mission_state.dart';
import '../widgets/add_mission_bottom_sheet.dart';
import '../widgets/mission_actions.dart';

/// Urgencia de una misión pendiente, para agrupar y colorear.
enum _Urgency { overdue, today, upcoming, noDate }

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  void _openCreate(BuildContext context) {
    final bloc = context.read<MissionBloc>();
    AddMissionBottomSheet.show(
      context,
      onSubmit:
          (r) => bloc.add(
            AddMission(title: r.title, note: r.note, dueDate: r.dueDate),
          ),
    );
  }

  void _openEdit(BuildContext context, Mission m) {
    final bloc = context.read<MissionBloc>();
    AddMissionBottomSheet.show(
      context,
      initial: m,
      onSubmit:
          (r) => bloc.add(
            EditMission(
              m.copyWith(
                title: r.title,
                note: r.note,
                clearNote: r.note == null,
                dueDate: r.dueDate,
                clearDueDate: r.dueDate == null,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CenteredContent(
        child: BlocBuilder<MissionBloc, MissionState>(
          builder: (context, state) {
            if (state is MissionLoading || state is MissionInitial) {
              return const _MissionsSkeleton();
            }
            if (state is MissionError) {
              return _ErrorView(
                message: state.message,
                onRetry:
                    () => context.read<MissionBloc>().add(const LoadMissions()),
              );
            }

            final loaded = state as MissionLoaded;
            final pending = loaded.pending;
            final completed = loaded.completed;

            if (pending.isEmpty && completed.isEmpty) {
              return _EmptyState(onCreate: () => _openCreate(context));
            }

            final groups = _groupByUrgency(pending);

            return RefreshIndicator(
              onRefresh:
                  () async =>
                      context.read<MissionBloc>().add(const LoadMissions()),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  _SummaryHeader(
                    pending: pending,
                    completedCount: completed.length,
                    groups: groups,
                  ),
                  const SizedBox(height: 4),
                  for (final u in _Urgency.values)
                    if ((groups[u] ?? const []).isNotEmpty) ...[
                      _GroupHeader(urgency: u, count: groups[u]!.length),
                      ...groups[u]!.map(
                        (m) => _MissionRow(
                          mission: m,
                          urgency: u,
                          onToggle:
                              () => toggleMissionWithUndo(
                                context,
                                context.read<MissionBloc>(),
                                m,
                              ),
                          onEdit: () => _openEdit(context, m),
                          onDelete:
                              () => deleteMissionWithUndo(
                                context,
                                context.read<MissionBloc>(),
                                m,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  if (completed.isNotEmpty)
                    _CompletedSection(
                      completed: completed,
                      onToggle:
                          (m) => toggleMissionWithUndo(
                            context,
                            context.read<MissionBloc>(),
                            m,
                          ),
                      onEdit: (m) => _openEdit(context, m),
                      onDelete:
                          (m) => deleteMissionWithUndo(
                            context,
                            context.read<MissionBloc>(),
                            m,
                          ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva misión'),
      ),
    );
  }

  static Map<_Urgency, List<Mission>> _groupByUrgency(List<Mission> pending) {
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    final map = <_Urgency, List<Mission>>{
      for (final u in _Urgency.values) u: [],
    };
    for (final m in pending) {
      map[_urgencyOf(m, today)]!.add(m);
    }
    return map;
  }
}

_Urgency _urgencyOf(Mission m, DateTime today) {
  final due = m.dueDate;
  if (due == null) return _Urgency.noDate;
  final d = AppDateUtils.getStartOfDay(due);
  if (d.isBefore(today)) return _Urgency.overdue;
  if (d == today) return _Urgency.today;
  return _Urgency.upcoming;
}

// ─── Encabezado resumen ────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final List<Mission> pending;
  final int completedCount;
  final Map<_Urgency, List<Mission>> groups;

  const _SummaryHeader({
    required this.pending,
    required this.completedCount,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = groups[_Urgency.overdue]?.length ?? 0;
    final today = groups[_Urgency.today]?.length ?? 0;
    final total = pending.length + completedCount;
    final ratio = total == 0 ? 0.0 : completedCount / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${pending.length}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pending.length == 1
                    ? 'misión pendiente'
                    : 'misiones pendientes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (overdue > 0 || today > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (overdue > 0)
                  _StatChip(
                    label: '$overdue vencida${overdue > 1 ? 's' : ''}',
                    fg: theme.colorScheme.error,
                    bg: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                  ),
                if (overdue > 0 && today > 0) const SizedBox(width: 8),
                if (today > 0)
                  _StatChip(
                    label: '$today para hoy',
                    fg: theme.colorScheme.primary,
                    bg: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                  ),
              ],
            ),
          ],
          if (total > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Completadas',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount / $total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _StatChip({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─── Encabezado de grupo ────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final _Urgency urgency;
  final int count;

  const _GroupHeader({required this.urgency, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _accentFor(context, urgency);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${_labelFor(urgency)} · $count',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  urgency == _Urgency.overdue || urgency == _Urgency.today
                      ? color
                      : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _labelFor(_Urgency u) => switch (u) {
  _Urgency.overdue => 'Vencidas',
  _Urgency.today => 'Hoy',
  _Urgency.upcoming => 'Próximas',
  _Urgency.noDate => 'Sin fecha',
};

Color _accentFor(BuildContext context, _Urgency u) {
  final scheme = Theme.of(context).colorScheme;
  return switch (u) {
    _Urgency.overdue => scheme.error,
    _Urgency.today => scheme.primary,
    _Urgency.upcoming => scheme.outline,
    _Urgency.noDate => scheme.outlineVariant,
  };
}

// ─── Fila de misión ─────────────────────────────────────────────────────────

class _MissionRow extends StatelessWidget {
  final Mission mission;
  final _Urgency urgency;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MissionRow({
    required this.mission,
    required this.urgency,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = mission.isDone;
    final accent = _accentFor(context, urgency);

    return Dismissible(
      key: ValueKey('mission_${mission.id}'),
      // Gesto unificado: izquierda = eliminar, derecha = marcar hecho.
      background: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _CompleteBg(),
      ),
      secondaryBackground: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _DeleteBg(),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: InkWell(
                  onTap: onToggle,
                  onLongPress: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color:
                                done
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                          ),
                          onPressed: onToggle,
                          tooltip: 'Completar',
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mission.title,
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (mission.note != null &&
                                  mission.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    mission.note!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              if (mission.dueDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    _relativeLabel(mission.dueDate!),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          urgency == _Urgency.overdue
                                              ? theme.colorScheme.error
                                              : theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteBg extends StatelessWidget {
  const _CompleteBg();
  @override
  Widget build(BuildContext context) => SwipeActionBackground.complete(context);
}

class _DeleteBg extends StatelessWidget {
  const _DeleteBg();
  @override
  Widget build(BuildContext context) => SwipeActionBackground.delete(context);
}

String _relativeLabel(DateTime due) {
  final today = AppDateUtils.getStartOfDay(DateTime.now());
  final d = AppDateUtils.getStartOfDay(due);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff < -1) return 'hace ${-diff} días';
  if (diff <= 7) return 'en $diff días';
  return _formatDate(due);
}

String _formatDate(DateTime d) {
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

// ─── Completadas (colapsable) ───────────────────────────────────────────────

class _CompletedSection extends StatefulWidget {
  final List<Mission> completed;
  final void Function(Mission) onToggle;
  final void Function(Mission) onEdit;
  final void Function(Mission) onDelete;

  const _CompletedSection({
    required this.completed,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Completadas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${widget.completed.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.completed.map(
            (m) => _CompletedRow(
              mission: m,
              onToggle: () => widget.onToggle(m),
              onEdit: () => widget.onEdit(m),
              onDelete: () => widget.onDelete(m),
            ),
          ),
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  final Mission mission;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompletedRow({
    required this.mission,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('mission_done_${mission.id}'),
      background: const Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: _CompleteBg(),
      ),
      secondaryBackground: const Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: _DeleteBg(),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        dense: true,
        onTap: onToggle,
        onLongPress: onEdit,
        leading: IconButton(
          icon: Icon(Icons.check_circle, color: theme.colorScheme.primary),
          onPressed: onToggle,
          tooltip: 'Reabrir',
        ),
        title: Text(
          mission.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Estados auxiliares ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de la primera carga de Misiones: encabezado resumen + filas.
class _MissionsSkeleton extends StatelessWidget {
  const _MissionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 200, height: 28),
              SizedBox(height: 14),
              Skeleton(height: 6, radius: 3),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Skeleton(width: 120, height: 14),
        const SizedBox(height: 10),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Skeleton(height: 60, radius: 10),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin misiones todavía',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las misiones son tareas de una sola vez: ir al dentista, '
              'hacer un trámite, un turno médico. Anótalas para no olvidarte.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear misión'),
            ),
          ],
        ),
      ),
    );
  }
}
