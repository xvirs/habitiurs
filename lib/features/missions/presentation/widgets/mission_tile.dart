import 'package:flutter/material.dart';

import '../../../../shared/utils/date_utils.dart';
import '../../domain/entities/mission.dart';

class MissionTile extends StatelessWidget {
  final Mission mission;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const MissionTile({
    super.key,
    required this.mission,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = mission.isDone;
    final overdue = mission.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color:
                      done
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                ),
                onPressed: onToggle,
                tooltip: done ? 'Marcar como pendiente' : 'Completar',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                        color:
                            done
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (mission.note != null && mission.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          mission.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (mission.dueDate != null) ...[
                      const SizedBox(height: 6),
                      _DueChip(
                        dueDate: mission.dueDate!,
                        overdue: overdue,
                        done: done,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueChip extends StatelessWidget {
  final DateTime dueDate;
  final bool overdue;
  final bool done;

  const _DueChip({
    required this.dueDate,
    required this.overdue,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color =
        overdue && !done
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overdue && !done ? Icons.warning_amber_rounded : Icons.event,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            overdue && !done ? 'Vencida · ${_label()}' : _label(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    final target = AppDateUtils.getStartOfDay(dueDate);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff == -1) return 'Ayer';
    return _formatDate(dueDate);
  }

  static String _formatDate(DateTime d) {
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
}
