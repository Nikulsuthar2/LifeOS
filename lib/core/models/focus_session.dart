class FocusSession {
  final String id;
  final String title;
  final String? taskId;
  final String? topicId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String sessionType; // 'focus', 'short_break', 'long_break'
  final String? notes;
  final bool isCompleted;

  FocusSession({
    required this.id,
    required this.title,
    this.taskId,
    this.topicId,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    this.sessionType = 'focus',
    this.notes,
    this.isCompleted = true,
  });

  int get durationMinutes => (durationSeconds / 60).round();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'task_id': taskId,
      'topic_id': topicId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'session_type': sessionType,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? 'Focus Session',
      taskId: map['task_id'] as String?,
      topicId: map['topic_id'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.tryParse(map['ended_at'] as String) : null,
      durationSeconds: (map['duration_seconds'] as int?) ?? 1500,
      sessionType: (map['session_type'] as String?) ?? 'focus',
      notes: map['notes'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 1) == 1,
    );
  }
}

