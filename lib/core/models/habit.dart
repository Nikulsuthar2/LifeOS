class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final String trackingType; // 'boolean' or 'numeric'
  final double targetValue;
  final String unit;
  final String frequency; // 'daily', 'weekly'
  final String icon;
  final int color;
  final bool isArchived;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.trackingType = 'boolean',
    this.targetValue = 1.0,
    this.unit = 'times',
    this.frequency = 'daily',
    this.icon = 'check_circle_outline',
    this.color = 0xFF6366F1,
    this.isArchived = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isNumeric => trackingType == 'numeric';

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? trackingType,
    double? targetValue,
    String? unit,
    String? frequency,
    String? icon,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      trackingType: trackingType ?? this.trackingType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'tracking_type': trackingType,
      'target_value': targetValue,
      'unit': unit,
      'frequency': frequency,
      'icon': icon,
      'color': color,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'General',
      trackingType: (map['tracking_type'] as String?) ?? 'boolean',
      targetValue: (map['target_value'] as num?)?.toDouble() ?? 1.0,
      unit: (map['unit'] as String?) ?? 'times',
      frequency: (map['frequency'] as String?) ?? 'daily',
      icon: (map['icon'] as String?) ?? 'check_circle_outline',
      color: (map['color'] as int?) ?? 0xFF6366F1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final String dateStr; // YYYY-MM-DD
  final double value;
  final bool isCompleted;
  final String? notes;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.dateStr,
    required this.value,
    required this.isCompleted,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date_str': dateStr,
      'value': value,
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      dateStr: map['date_str'] as String,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
    );
  }
}

