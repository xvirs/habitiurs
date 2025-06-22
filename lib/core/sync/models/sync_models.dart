// lib/core/sync/models/sync_models.dart
enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
  conflict,
}

enum SyncOperationType {
  create,
  update,
  delete,
}

class SyncOperation {
  final String id;
  final String entityType; // 'habit', 'habit_entry', 'user_preferences'
  final String entityId;
  final SyncOperationType operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final SyncStatus status;
  final String? error;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.status = SyncStatus.pending,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'error': error,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      operation: SyncOperationType.values.byName(json['operation']),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      status: SyncStatus.values.byName(json['status']),
      error: json['error'],
    );
  }

  SyncOperation copyWith({
    SyncStatus? status,
    String? error,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      timestamp: timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}