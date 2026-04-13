/// Represents a Field Agent task stored locally in SQLite
/// and optionally synced to Cloud Firestore.
class TaskModel {
  final int? id;           // SQLite auto-increment primary key
  final String title;
  final String description;
  final String priority;   // low | medium | high
  final bool synced;       // false = pending sync to Firestore
  final String userId;
  final DateTime createdAt;
  final String? firestoreId; // set after successful Firestore write

  const TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.synced = false,
    required this.userId,
    required this.createdAt,
    this.firestoreId,
  });

  // ─── SQLite ───────────────────────────────────────────────────────────────

  /// Converts this model into a map suitable for SQLite insertion.
  Map<String, dynamic> toSqliteMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'synced': synced ? 1 : 0,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'firestoreId': firestoreId,
    };
  }

  /// Creates a [TaskModel] from a SQLite row map.
  factory TaskModel.fromSqliteMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      priority: map['priority'] as String? ?? 'medium',
      synced: (map['synced'] as int? ?? 0) == 1,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      firestoreId: map['firestoreId'] as String?,
    );
  }

  // ─── Firestore ────────────────────────────────────────────────────────────

  /// Converts this model into a map for Firestore document.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'syncedAt': DateTime.now().toIso8601String(),
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns a copy with updated fields.
  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    String? priority,
    bool? synced,
    String? userId,
    DateTime? createdAt,
    String? firestoreId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      synced: synced ?? this.synced,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }
}