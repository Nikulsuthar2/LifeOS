enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  static TaskPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }
}

enum TaskStatus {
  inbox,
  todo,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TaskStatus.inbox:
        return 'Inbox';
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TaskStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'inbox':
        return TaskStatus.inbox;
      case 'in_progress':
      case 'inprogress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'todo':
      default:
        return TaskStatus.todo;
    }
  }

  String toDbString() {
    switch (this) {
      case TaskStatus.inbox:
        return 'inbox';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
      case TaskStatus.todo:
        return 'todo';
    }
  }
}

class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
  });

  Subtask copyWith({
    String? id,
    String? taskId,
    String? title,
    bool? isCompleted,
    int? position,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'position': position,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      position: map['position'] as int? ?? 0,
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? scheduledTime;
  final int estimateMinutes;
  final int actualMinutes;
  final String? projectId;
  final String? goalId;
  final String? roadmapTopicId;
  final bool isTopPriority;
  final String recurrence; // 'none', 'daily', 'weekly'
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Subtask> subtasks;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.scheduledTime,
    this.estimateMinutes = 30,
    this.actualMinutes = 0,
    this.projectId,
    this.goalId,
    this.roadmapTopicId,
    this.isTopPriority = false,
    this.recurrence = 'none',
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.subtasks = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isCompleted => status == TaskStatus.completed;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? scheduledTime,
    int? estimateMinutes,
    int? actualMinutes,
    String? projectId,
    String? goalId,
    String? roadmapTopicId,
    bool? isTopPriority,
    String? recurrence,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Subtask>? subtasks,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      projectId: projectId ?? this.projectId,
      goalId: goalId ?? this.goalId,
      roadmapTopicId: roadmapTopicId ?? this.roadmapTopicId,
      isTopPriority: isTopPriority ?? this.isTopPriority,
      recurrence: recurrence ?? this.recurrence,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toDbString(),
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'scheduled_time': scheduledTime,
      'estimate_minutes': estimateMinutes,
      'actual_minutes': actualMinutes,
      'project_id': projectId,
      'goal_id': goalId,
      'roadmap_topic_id': roadmapTopicId,
      'is_top_priority': isTopPriority ? 1 : 0,
      'recurrence': recurrence,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map, {List<Subtask> subtasks = const []}) {
    return TaskItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      status: TaskStatus.fromString(map['status'] as String?),
      priority: TaskPriority.fromString(map['priority'] as String?),
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'] as String) : null,
      scheduledTime: map['scheduled_time'] as String?,
      estimateMinutes: (map['estimate_minutes'] as int?) ?? 30,
      actualMinutes: (map['actual_minutes'] as int?) ?? 0,
      projectId: map['project_id'] as String?,
      goalId: map['goal_id'] as String?,
      roadmapTopicId: map['roadmap_topic_id'] as String?,
      isTopPriority: (map['is_top_priority'] as int? ?? 0) == 1,
      recurrence: (map['recurrence'] as String?) ?? 'none',
      completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
      subtasks: subtasks,
    );
  }
}

