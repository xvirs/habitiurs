import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
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

  /// Atajo desde el chip "+ fecha": asigna fecha límite sin abrir el sheet.
  Future<void> _pickDateFor(BuildContext context, Mission m) async {
    final bloc = context.read<MissionBloc>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha límite',
    );
    if (picked != null) {
      bloc.add(EditMission(m.copyWith(dueDate: picked)));
    }
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

            final bloc = context.read<MissionBloc>();
            final groups = _groupByUrgency(pending);
            final nonEmptyGroups =
                groups.values.where((l) => l.isNotEmpty).length;

            // Completadas de hoy quedan a la vista (tachadas, en verde) como
            // "logros del día"; las de días anteriores se pliegan abajo para
            // no acumular una lista infinita.
            final startToday = AppDateUtils.getStartOfDay(DateTime.now());
            final doneToday = <Mission>[];
            final doneOlder = <Mission>[];
            for (final m in completed) {
              final c = m.completedAt;
              if (c != null &&
                  !AppDateUtils.getStartOfDay(c).isBefore(startToday)) {
                doneToday.add(m);
              } else {
                doneOlder.add(m);
              }
            }
            // La recién completada aparece arriba del todo en "Hechas hoy".
            doneToday.sort(
              (a, b) => (b.completedAt ?? DateTime(0)).compareTo(
                a.completedAt ?? DateTime(0),
              ),
            );

            void onToggle(Mission m) => toggleMissionWithUndo(context, bloc, m);
            void onDelete(Mission m) => deleteMissionWithUndo(context, bloc, m);

            final scheme = Theme.of(context).colorScheme;
            final green = AppColors.completed(context);
            // Cada estante inferior scrollea adentro con un alto acotado.
            final shelfMax = MediaQuery.sizeOf(context).height * 0.34;
            final hasShelves = doneToday.isNotEmpty || doneOlder.isNotEmpty;

            List<Widget> completedRows(
              List<Mission> list,
              Color accent,
              bool tinted,
            ) => [
              for (var i = 0; i < list.length; i++)
                _CompletedRow(
                  mission: list[i],
                  showDivider: i > 0,
                  accent: accent,
                  tinted: tinted,
                  onToggle: () => onToggle(list[i]),
                  onEdit: () => _openEdit(context, list[i]),
                  onDelete: () => onDelete(list[i]),
                ),
            ];

            return Column(
              children: [
                // Encabezado resumen: fijo arriba.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: _SummaryHeader(
                    pending: pending,
                    completedThisMonth: _completedThisMonth(completed),
                    groups: groups,
                  ),
                ),
                // Pendientes: se llevan el mayor espacio, con scroll propio.
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => bloc.add(const LoadMissions()),
                    child:
                        pending.isEmpty
                            ? const _AllClearView()
                            : ListView(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                4,
                                12,
                                hasShelves ? 12 : 88,
                              ),
                              children: [
                                for (final u in _Urgency.values)
                                  if (groups[u]!.isNotEmpty) ...[
                                    // Con un solo grupo el encabezado no aporta.
                                    if (nonEmptyGroups > 1)
                                      _GroupHeader(
                                        urgency: u,
                                        count: groups[u]!.length,
                                      ),
                                    _MissionGroupCard(
                                      missions: groups[u]!,
                                      urgency: u,
                                      onToggle: onToggle,
                                      onEdit: (m) => _openEdit(context, m),
                                      onDelete: onDelete,
                                      onPickDate:
                                          (m) => _pickDateFor(context, m),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                              ],
                            ),
                  ),
                ),
                // Pies fijos: "Hechas hoy" y "Completadas anteriores".
                if (doneToday.isNotEmpty)
                  _CollapsibleShelf(
                    key: const ValueKey('shelf_today'),
                    icon: Icons.check_circle,
                    accent: green,
                    title: 'Hechas hoy',
                    count: doneToday.length,
                    initiallyExpanded: true,
                    maxHeight: shelfMax,
                    reserveFabSpace: doneOlder.isEmpty,
                    rows: completedRows(doneToday, green, true),
                  ),
                if (doneOlder.isNotEmpty)
                  _CollapsibleShelf(
                    key: const ValueKey('shelf_older'),
                    icon: Icons.history,
                    accent: scheme.onSurfaceVariant,
                    title: 'Completadas anteriores',
                    count: doneOlder.length,
                    initiallyExpanded: false,
                    maxHeight: shelfMax,
                    reserveFabSpace: true,
                    rows: completedRows(doneOlder, scheme.primary, false),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context),
        tooltip: 'Nueva misión',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Completadas dentro del mes calendario actual (más útil que un total
  /// histórico que solo crece).
  static int _completedThisMonth(List<Mission> completed) {
    final now = DateTime.now();
    return completed.where((m) {
      final c = m.completedAt;
      return c != null && c.year == now.year && c.month == now.month;
    }).length;
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
  final int completedThisMonth;
  final Map<_Urgency, List<Mission>> groups;

  const _SummaryHeader({
    required this.pending,
    required this.completedThisMonth,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = groups[_Urgency.overdue]?.length ?? 0;
    final today = groups[_Urgency.today]?.length ?? 0;
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
                pending.length == 1 ? 'pendiente' : 'pendientes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (completedThisMonth > 0)
                Text(
                  '$completedThisMonth completada'
                  '${completedThisMonth > 1 ? "s" : ""} este mes',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.completed(context),
                    fontWeight: FontWeight.w600,
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

/// Tarjeta contenedora de un grupo: una sola caja con filas divididas
/// (menos ruido visual que una tarjeta bordeada por misión).
class _MissionGroupCard extends StatelessWidget {
  final List<Mission> missions;
  final _Urgency urgency;
  final void Function(Mission) onToggle;
  final void Function(Mission) onEdit;
  final void Function(Mission) onDelete;
  final void Function(Mission) onPickDate;

  const _MissionGroupCard({
    required this.missions,
    required this.urgency,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            for (var i = 0; i < missions.length; i++)
              _MissionRow(
                mission: missions[i],
                urgency: urgency,
                showDivider: i > 0,
                onToggle: () => onToggle(missions[i]),
                onEdit: () => onEdit(missions[i]),
                onDelete: () => onDelete(missions[i]),
                onPickDate: () => onPickDate(missions[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final Mission mission;
  final _Urgency urgency;
  final bool showDivider;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPickDate;

  const _MissionRow({
    required this.mission,
    required this.urgency,
    required this.showDivider,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(context, urgency);
    final hasNote = mission.note != null && mission.note!.isNotEmpty;

    return Dismissible(
      key: ValueKey('mission_${mission.id}'),
      // Gesto unificado: izquierda = eliminar, derecha = marcar hecho.
      background: const _CompleteBg(),
      secondaryBackground: const _DeleteBg(),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border:
              showDivider
                  ? Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  )
                  : null,
        ),
        child: InkWell(
          onTap: onToggle,
          onLongPress: onEdit,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Franja de urgencia (identidad a la izquierda).
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mission.title,
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (hasNote)
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
                        // Empujón para que las misiones sin fecha entren al
                        // tablero y a los recordatorios.
                        if (mission.dueDate == null) ...[
                          const SizedBox(width: 8),
                          _AddDateChip(onTap: onPickDate),
                        ],
                        const SizedBox(width: 4),
                        // Acción a la derecha (misma anatomía que Hábitos).
                        IconButton(
                          icon: Icon(
                            Icons.radio_button_unchecked,
                            color: theme.colorScheme.outline,
                          ),
                          iconSize: 26,
                          onPressed: onToggle,
                          tooltip: 'Completar',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddDateChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddDateChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Neutro a propósito: con muchas misiones sin fecha, una pila de chips
    // de acento competía con los títulos. Es un atajo, no una llamada.
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return IconButton(
      onPressed: onTap,
      icon: Icon(Icons.event_outlined, size: 18, color: color),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      tooltip: 'Poner fecha límite',
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

// ─── Estante colapsable (pie fijo) ──────────────────────────────────────────

/// Barra fija al pie de la pantalla con un panel plegable de scroll propio.
/// Su encabezado ("Hechas hoy", "Completadas anteriores") queda SIEMPRE
/// visible; al abrirlo, la lista scrollea dentro de un alto acotado sin tapar
/// los pendientes de arriba.
class _CollapsibleShelf extends StatefulWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final int count;
  final bool initiallyExpanded;
  final double maxHeight;

  /// Reserva un hueco a la derecha del encabezado para no quedar debajo del FAB.
  final bool reserveFabSpace;
  final List<Widget> rows;

  const _CollapsibleShelf({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.count,
    required this.initiallyExpanded,
    required this.maxHeight,
    required this.rows,
    this.reserveFabSpace = false,
  });

  @override
  State<_CollapsibleShelf> createState() => _CollapsibleShelfState();
}

class _CollapsibleShelfState extends State<_CollapsibleShelf> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado fijo (siempre visible).
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: widget.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.title} · ${widget.count}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.accent,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  // Deja libre la esquina inferior derecha para el FAB.
                  if (widget.reserveFabSpace) const SizedBox(width: 56),
                ],
              ),
            ),
          ),
          // Panel con scroll interno acotado.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.bottomCenter,
            child:
                _expanded
                    ? ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: widget.maxHeight),
                      child: Scrollbar(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: widget.rows,
                        ),
                      ),
                    )
                    : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Zona de pendientes cuando no queda ninguno (pero sí hay completadas).
class _AllClearView extends StatelessWidget {
  const _AllClearView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 56,
          color: AppColors.completed(context),
        ),
        const SizedBox(height: 14),
        Text(
          '¡Sin pendientes!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estás al día con tus misiones.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  final Mission mission;
  final bool showDivider;
  final Color? accent;
  final bool tinted;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompletedRow({
    required this.mission,
    this.showDivider = false,
    this.accent,
    this.tinted = false,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Dismissible(
      key: ValueKey('mission_done_${mission.id}'),
      // Mismo gesto que en pendientes: derecha = reabrir, izquierda = eliminar.
      background: const _CompleteBg(),
      secondaryBackground: const _DeleteBg(),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          onToggle();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tinted ? color.withValues(alpha: 0.06) : null,
          border:
              showDivider
                  ? Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  )
                  : null,
        ),
        child: InkWell(
          onTap: onToggle,
          onLongPress: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mission.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check_circle, color: color),
                  iconSize: 24,
                  onPressed: onToggle,
                  tooltip: 'Reabrir',
                ),
              ],
            ),
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
