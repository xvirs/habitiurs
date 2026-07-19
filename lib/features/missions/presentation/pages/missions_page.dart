import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/utils/responsive.dart';
import '../../domain/entities/mission.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_event.dart';
import '../bloc/mission_state.dart';
import '../widgets/add_mission_bottom_sheet.dart';
import '../widgets/mission_tile.dart';

class MissionsPage extends StatelessWidget {
  const MissionsPage({super.key});

  void _openCreate(BuildContext context) {
    final bloc = context.read<MissionBloc>();
    AddMissionBottomSheet.show(
      context,
      onSubmit: (result) {
        bloc.add(
          AddMission(
            title: result.title,
            note: result.note,
            dueDate: result.dueDate,
          ),
        );
      },
    );
  }

  void _openEdit(BuildContext context, Mission mission) {
    final bloc = context.read<MissionBloc>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CenteredContent(
        child: BlocBuilder<MissionBloc, MissionState>(
          builder: (context, state) {
            if (state is MissionLoading || state is MissionInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MissionError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed:
                            () => context.read<MissionBloc>().add(
                              const LoadMissions(),
                            ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state as MissionLoaded;
            final pending = loaded.pending;
            final completed = loaded.completed;

            if (pending.isEmpty && completed.isEmpty) {
              return _EmptyState(onCreate: () => _openCreate(context));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MissionBloc>().add(const LoadMissions());
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                children: [
                  if (pending.isNotEmpty) ...[
                    const _SectionHeader(title: 'Pendientes'),
                    ...pending.map(
                      (m) => _DismissibleMission(
                        mission: m,
                        onToggle:
                            () => context.read<MissionBloc>().add(
                              ToggleMissionDone(m),
                            ),
                        onEdit: () => _openEdit(context, m),
                        onDelete:
                            () => context.read<MissionBloc>().add(
                              RemoveMission(m.id!),
                            ),
                      ),
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    _SectionHeader(title: 'Completadas (${completed.length})'),
                    ...completed.map(
                      (m) => _DismissibleMission(
                        mission: m,
                        onToggle:
                            () => context.read<MissionBloc>().add(
                              ToggleMissionDone(m),
                            ),
                        onEdit: () => _openEdit(context, m),
                        onDelete:
                            () => context.read<MissionBloc>().add(
                              RemoveMission(m.id!),
                            ),
                      ),
                    ),
                  ],
                ],
              ),
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
}

class _DismissibleMission extends StatelessWidget {
  final Mission mission;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DismissibleMission({
    required this.mission,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('mission_${mission.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('¿Eliminar misión?'),
                    content: Text('"${mission.title}" se eliminará.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: MissionTile(mission: mission, onToggle: onToggle, onEdit: onEdit),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
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
