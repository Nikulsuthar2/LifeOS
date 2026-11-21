class Milestone {
  final String id;
  final String goalId;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;

  Milestone({
    required this.id,
    required this.goalId,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  });

  Milestone copyWith({
    String? id,
    String? goalId,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
  }) {
    return Milestone(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'] as String) : null,
    );
  }
}

class Goal {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? targetDate;
  final String status; // 'active', 'completed', 'paused'
  final DateTime createdAt;
  final List<Milestone> milestones;

  Goal({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Career',
    this.targetDate,
    this.status = 'active',
    DateTime? createdAt,
    this.milestones = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercentage {
    if (milestones.isEmpty) return status == 'completed' ? 1.0 : 0.0;
    return milestones.where((m) => m.isCompleted).length / milestones.length;
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? targetDate,
    String? status,
    DateTime? createdAt,
    List<Milestone>? milestones,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'target_date': targetDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map, {List<Milestone> milestones = const []}) {
    return Goal(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Career',
      targetDate: map['target_date'] != null ? DateTime.tryParse(map['target_date'] as String) : null,
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      milestones: milestones,
    );
  }
}

class ProjectFeature {
  final String id;
  final String projectId;
  final String title;
  final String status; // 'upcoming', 'in_progress', 'done'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final int position;
  final DateTime createdAt;

  ProjectFeature({
    required this.id,
    required this.projectId,
    required this.title,
    this.status = 'upcoming',
    this.priority = 'medium',
    this.position = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ProjectFeature copyWith({
    String? id,
    String? projectId,
    String? title,
    String? status,
    String? priority,
    int? position,
    DateTime? createdAt,
  }) {
    return ProjectFeature(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'status': status,
      'priority': priority,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ProjectFeature.fromMap(Map<String, dynamic> map) {
    return ProjectFeature(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      title: map['title'] as String,
      status: (map['status'] as String?) ?? 'upcoming',
      priority: (map['priority'] as String?) ?? 'medium',
      position: (map['position'] as int? ?? 0),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class Project {
  final String id;
  final String title;
  final String description;
  final String? categoryId;
  final String? goalId;
  final String status; // 'active', 'completed', 'on_hold'
  final DateTime? targetDate;
  final int color;
  final DateTime createdAt;
  final List<ProjectFeature> features;

  Project({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryId,
    this.goalId,
    this.status = 'active',
    this.targetDate,
    this.color = 0xFF6366F1,
    DateTime? createdAt,
    this.features = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercentage {
    if (features.isEmpty) return status == 'completed' ? 1.0 : 0.0;
    return features.where((f) => f.status == 'done').length / features.length;
  }

  Project copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? goalId,
    String? status,
    DateTime? targetDate,
    int? color,
    DateTime? createdAt,
    List<ProjectFeature>? features,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      goalId: goalId ?? this.goalId,
      status: status ?? this.status,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      features: features ?? this.features,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'goal_id': goalId,
      'status': status,
      'target_date': targetDate?.toIso8601String(),
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, {List<ProjectFeature> features = const []}) {
    return Project(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      categoryId: map['category_id'] as String?,
      goalId: map['goal_id'] as String?,
      status: (map['status'] as String?) ?? 'active',
      targetDate: map['target_date'] != null ? DateTime.tryParse(map['target_date'] as String) : null,
      color: (map['color'] as int?) ?? 0xFF6366F1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      features: features,
    );
  }
}
