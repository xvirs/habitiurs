import 'package:equatable/equatable.dart';

import '../../../../shared/utils/date_utils.dart';

/// Una "misión": tarea de una sola vez (no recurrente como un hábito).
/// Ej: ir al dentista, hacer un trámite. Se completa una vez y listo.
class Mission extends Equatable {
  final int? id;
  final String title;
  final String? note;
  final bool isDone;

  /// Fecha límite opcional.
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Tombstone: borrado lógico que se propaga entre dispositivos.
  final bool isDeleted;

  /// Timestamp del último cambio, para resolver conflictos en el sync.
  final DateTime? lastModified;

  const Mission({
    this.id,
    required this.title,
    this.note,
    this.isDone = false,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.isDeleted = false,
    this.lastModified,
  });

  /// Vencida = tiene fecha límite pasada y todavía no se completó.
  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    final today = AppDateUtils.getStartOfDay(DateTime.now());
    return AppDateUtils.getStartOfDay(dueDate!).isBefore(today);
  }

  Mission copyWith({
    int? id,
    String? title,
    String? note,
    bool clearNote = false,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? isDeleted,
    DateTime? lastModified,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      isDone: isDone ?? this.isDone,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    note,
    isDone,
    dueDate,
    createdAt,
    completedAt,
    isDeleted,
    lastModified,
  ];
}
