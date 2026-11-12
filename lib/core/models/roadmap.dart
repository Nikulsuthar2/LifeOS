enum TopicStatus {
  locked,
  available,
  inProgress,
  completed,
  onHold;

  String get displayName {
    switch (this) {
      case TopicStatus.locked:
        return 'Locked';
      case TopicStatus.available:
        return 'Available';
      case TopicStatus.inProgress:
        return 'In Progress';
      case TopicStatus.completed:
        return 'Completed';
      case TopicStatus.onHold:
        return 'On Hold';
    }
  }

  static TopicStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'locked':
        return TopicStatus.locked;
      case 'in_progress':
      case 'inprogress':
        return TopicStatus.inProgress;
      case 'completed':
        return TopicStatus.completed;
      case 'on_hold':
      case 'onhold':
        return TopicStatus.onHold;
      case 'available':
      default:
        return TopicStatus.available;
    }
  }

  String toDbString() {
    switch (this) {
      case TopicStatus.locked:
        return 'locked';
      case TopicStatus.inProgress:
        return 'in_progress';
      case TopicStatus.completed:
        return 'completed';
      case TopicStatus.onHold:
        return 'on_hold';
      case TopicStatus.available:
        return 'available';
    }
  }
}

class TopicResource {
  final String id;
  final String topicId;
  final String title;
  final String resourceType; // 'video', 'doc', 'book', 'url'
  final String url;
  final String notes;

  TopicResource({
    required this.id,
    required this.topicId,
    required this.title,
    this.resourceType = 'url',
    this.url = '',
    this.notes = '',
  });

  TopicResource copyWith({
    String? id,
    String? topicId,
    String? title,
    String? resourceType,
    String? url,
    String? notes,
  }) {
    return TopicResource(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      resourceType: resourceType ?? this.resourceType,
      url: url ?? this.url,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'title': title,
      'resource_type': resourceType,
      'url': url,
      'notes': notes,
    };
  }

  factory TopicResource.fromMap(Map<String, dynamic> map) {
    return TopicResource(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      title: map['title'] as String,
      resourceType: (map['resource_type'] as String?) ?? 'url',
      url: (map['url'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

class Lesson {
  final String id;
  final String topicId;
  final String title;
  final int position;
  final bool isCompleted;

  Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    this.position = 0,
    this.isCompleted = false,
  });

  Lesson copyWith({
    String? id,
    String? topicId,
    String? title,
    int? position,
    bool? isCompleted,
  }) {
    return Lesson(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      position: position ?? this.position,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'title': title,
      'position': position,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      topicId: map['topic_id'] as String,
      title: map['title'] as String,
      position: (map['position'] as int?) ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }
}

class Topic {
  final String id;
  final String stageId;
  final String title;
  final String description;
  final int position;
  final TopicStatus status;
  final double estimatedHours;
  final int actualMinutesSpent;
  final String? prerequisiteTopicId;
  final List<Lesson> lessons;
  final List<TopicResource> resources;

  Topic({
    required this.id,
    required this.stageId,
    required this.title,
    this.description = '',
    this.position = 0,
    this.status = TopicStatus.available,
    this.estimatedHours = 2.0,
    this.actualMinutesSpent = 0,
    this.prerequisiteTopicId,
    this.lessons = const [],
    this.resources = const [],
  });

  int get completedLessonsCount => lessons.where((l) => l.isCompleted).length;
  double get progressPercentage => lessons.isEmpty ? (status == TopicStatus.completed ? 1.0 : 0.0) : completedLessonsCount / lessons.length;

  Topic copyWith({
    String? id,
    String? stageId,
    String? title,
    String? description,
    int? position,
    TopicStatus? status,
    double? estimatedHours,
    int? actualMinutesSpent,
    String? prerequisiteTopicId,
    List<Lesson>? lessons,
    List<TopicResource>? resources,
  }) {
    return Topic(
      id: id ?? this.id,
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      status: status ?? this.status,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualMinutesSpent: actualMinutesSpent ?? this.actualMinutesSpent,
      prerequisiteTopicId: prerequisiteTopicId ?? this.prerequisiteTopicId,
      lessons: lessons ?? this.lessons,
      resources: resources ?? this.resources,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stage_id': stageId,
      'title': title,
      'description': description,
      'position': position,
      'status': status.toDbString(),
      'estimated_hours': estimatedHours,
      'actual_minutes_spent': actualMinutesSpent,
      'prerequisite_topic_id': prerequisiteTopicId,
    };
  }

  factory Topic.fromMap(
    Map<String, dynamic> map, {
    List<Lesson> lessons = const [],
    List<TopicResource> resources = const [],
  }) {
    return Topic(
      id: map['id'] as String,
      stageId: map['stage_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      position: (map['position'] as int?) ?? 0,
      status: TopicStatus.fromString(map['status'] as String?),
      estimatedHours: (map['estimated_hours'] as num?)?.toDouble() ?? 2.0,
      actualMinutesSpent: (map['actual_minutes_spent'] as int?) ?? 0,
      prerequisiteTopicId: map['prerequisite_topic_id'] as String?,
      lessons: lessons,
      resources: resources,
    );
  }
}

class RoadmapStage {
  final String id;
  final String roadmapId;
  final String title;
  final String description;
  final int position;
  final List<Topic> topics;

  RoadmapStage({
    required this.id,
    required this.roadmapId,
    required this.title,
    this.description = '',
    this.position = 0,
    this.topics = const [],
  });

  int get completedTopicsCount => topics.where((t) => t.status == TopicStatus.completed).length;
  double get progressPercentage => topics.isEmpty ? 0.0 : completedTopicsCount / topics.length;

  RoadmapStage copyWith({
    String? id,
    String? roadmapId,
    String? title,
    String? description,
    int? position,
    List<Topic>? topics,
  }) {
    return RoadmapStage(
      id: id ?? this.id,
      roadmapId: roadmapId ?? this.roadmapId,
      title: title ?? this.title,
      description: description ?? this.description,
      position: position ?? this.position,
      topics: topics ?? this.topics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roadmap_id': roadmapId,
      'title': title,
      'description': description,
      'position': position,
    };
  }

  factory RoadmapStage.fromMap(Map<String, dynamic> map, {List<Topic> topics = const []}) {
    return RoadmapStage(
      id: map['id'] as String,
      roadmapId: map['roadmap_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      position: (map['position'] as int?) ?? 0,
      topics: topics,
    );
  }
}

class Roadmap {
  final String id;
  final String title;
  final String description;
  final String category;
  final int color;
  final String icon;
  final String status; // 'active', 'paused', 'completed'
  final DateTime createdAt;
  final List<RoadmapStage> stages;

  Roadmap({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Tech',
    this.color = 0xFF6366F1,
    this.icon = 'school',
    this.status = 'active',
    DateTime? createdAt,
    this.stages = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalTopicsCount {
    int total = 0;
    for (final stage in stages) {
      total += stage.topics.length;
    }
    return total;
  }

  int get completedTopicsCount {
    int count = 0;
    for (final stage in stages) {
      count += stage.topics.where((t) => t.status == TopicStatus.completed).length;
    }
    return count;
  }

  double get progressPercentage {
    if (totalTopicsCount == 0) return 0.0;
    return completedTopicsCount / totalTopicsCount;
  }

  Topic? get nextAvailableTopic {
    for (final stage in stages) {
      for (final topic in stage.topics) {
        if (topic.status == TopicStatus.inProgress || topic.status == TopicStatus.available) {
          return topic;
        }
      }
    }
    return null;
  }

  Roadmap copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? color,
    String? icon,
    String? status,
    DateTime? createdAt,
    List<RoadmapStage>? stages,
  }) {
    return Roadmap(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'icon': icon,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Roadmap.fromMap(Map<String, dynamic> map, {List<RoadmapStage> stages = const []}) {
    return Roadmap(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Tech',
      color: (map['color'] as int?) ?? 0xFF6366F1,
      icon: (map['icon'] as String?) ?? 'school',
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      stages: stages,
    );
  }
}
