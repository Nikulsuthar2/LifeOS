import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 3 states for each habit day:
/// - pending: uncompleted / neutral
/// - done: completed successfully
/// - fail: missed or failed
enum HabitDayStatus {
  pending,
  done,
  fail;

  String get dbValue => name;

  static HabitDayStatus fromDbValue(String? val) {
    if (val == 'done') return HabitDayStatus.done;
    if (val == 'fail') return HabitDayStatus.fail;
    return HabitDayStatus.pending;
  }

  HabitDayStatus get next {
    switch (this) {
      case HabitDayStatus.pending:
        return HabitDayStatus.done;
      case HabitDayStatus.done:
        return HabitDayStatus.fail;
      case HabitDayStatus.fail:
        return HabitDayStatus.pending;
    }
  }
}

class HabitCategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final int color;
  final bool isCustom;

  const HabitCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });
}

class HabitCategoryPresets {
  static const List<HabitCategoryItem> all = [
    HabitCategoryItem(
      id: 'health',
      name: 'Health',
      icon: CupertinoIcons.heart_fill,
      color: 0xFF10B981, // Emerald
    ),
    HabitCategoryItem(
      id: 'art',
      name: 'Art',
      icon: CupertinoIcons.paintbrush_fill,
      color: 0xFFEC4899, // Pink
    ),
    HabitCategoryItem(
      id: 'meditation',
      name: 'Meditation',
      icon: Icons.self_improvement_rounded,
      color: 0xFF8B5CF6, // Purple
    ),
    HabitCategoryItem(
      id: 'study',
      name: 'Study',
      icon: CupertinoIcons.book_fill,
      color: 0xFF3B82F6, // Blue
    ),
    HabitCategoryItem(
      id: 'sport',
      name: 'Sport',
      icon: CupertinoIcons.sportscourt_fill,
      color: 0xFFF97316, // Orange
    ),
    HabitCategoryItem(
      id: 'entertainment',
      name: 'Entertainment',
      icon: CupertinoIcons.game_controller_solid,
      color: 0xFF6366F1, // Indigo
    ),
    HabitCategoryItem(
      id: 'social',
      name: 'Social',
      icon: CupertinoIcons.person_2_fill,
      color: 0xFF14B8A6, // Teal
    ),
    HabitCategoryItem(
      id: 'finance',
      name: 'Finance',
      icon: CupertinoIcons.money_dollar_circle_fill,
      color: 0xFFEAB308, // Amber/Yellow
    ),
    HabitCategoryItem(
      id: 'work',
      name: 'Work',
      icon: CupertinoIcons.briefcase_fill,
      color: 0xFF64748B, // Slate
    ),
    HabitCategoryItem(
      id: 'home',
      name: 'Home',
      icon: CupertinoIcons.house_fill,
      color: 0xFF06B6D4, // Cyan
    ),
    HabitCategoryItem(
      id: 'reading',
      name: 'Reading',
      icon: CupertinoIcons.book_solid,
      color: 0xFFA855F7, // Violet
    ),
  ];

  static HabitCategoryItem getCategory(String name) {
    final lower = name.trim().toLowerCase();
    for (final item in all) {
      if (item.name.toLowerCase() == lower || item.id == lower) {
        return item;
      }
    }
    // Fallback for custom or unknown category
    return HabitCategoryItem(
      id: lower,
      name: name.isEmpty ? 'General' : name,
      icon: CupertinoIcons.bolt_fill,
      color: 0xFF6366F1,
      isCustom: true,
    );
  }

  static IconData getIconForName(String iconName) {
    switch (iconName) {
      case 'heart':
      case 'fitness_center':
      case 'health':
        return CupertinoIcons.heart_fill;
      case 'paintbrush':
      case 'art':
        return CupertinoIcons.paintbrush_fill;
      case 'meditation':
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'book':
      case 'study':
      case 'school':
        return CupertinoIcons.book_fill;
      case 'sport':
      case 'sportscourt':
        return CupertinoIcons.sportscourt_fill;
      case 'game':
      case 'entertainment':
        return CupertinoIcons.game_controller_solid;
      case 'social':
      case 'people':
      case 'person_2':
        return CupertinoIcons.person_2_fill;
      case 'finance':
      case 'money':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'work':
      case 'briefcase':
        return CupertinoIcons.briefcase_fill;
      case 'home':
        return CupertinoIcons.house_fill;
      case 'reading':
      case 'menu_book':
        return CupertinoIcons.book_solid;
      case 'water_drop':
        return Icons.water_drop;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.bolt;
    }
  }
}

class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final String trackingType; // 'boolean' or 'numeric'
  final double targetValue;
  final String unit;
  final String frequency; // 'daily', 'specific_days'
  final List<int> daysOfWeek; // 1 = Monday .. 7 = Sunday
  final String timeOfDay; // 'all', 'morning', 'afternoon', 'evening', 'night'
  final String priority; // 'low', 'medium', 'high'
  final DateTime startDate;
  final DateTime? endDate; // null if forever
  final String icon;
  final int color;
  final bool isArchived;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Health',
    this.trackingType = 'boolean',
    this.targetValue = 1.0,
    this.unit = 'times',
    this.frequency = 'daily',
    List<int>? daysOfWeek,
    this.timeOfDay = 'all',
    this.priority = 'medium',
    DateTime? startDate,
    this.endDate,
    this.icon = 'bolt',
    this.color = 0xFF6366F1,
    this.isArchived = false,
    DateTime? createdAt,
  })  : daysOfWeek = daysOfWeek ?? const [1, 2, 3, 4, 5, 6, 7],
        startDate = startDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isNumeric => trackingType == 'numeric';
  bool get isForever => endDate == null;

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? trackingType,
    double? targetValue,
    String? unit,
    String? frequency,
    List<int>? daysOfWeek,
    String? timeOfDay,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
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
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
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
      'days_of_week': jsonEncode(daysOfWeek),
      'time_of_day': timeOfDay,
      'priority': priority,
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'end_date': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
      'icon': icon,
      'color': color,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    DateTime parsedStartDate;
    if (map['start_date'] != null && (map['start_date'] as String).isNotEmpty) {
      parsedStartDate = DateTime.tryParse(map['start_date'] as String) ?? DateTime.now();
    } else {
      parsedStartDate = DateTime.now();
    }

    DateTime? parsedEndDate;
    if (map['end_date'] != null && (map['end_date'] as String).isNotEmpty) {
      parsedEndDate = DateTime.tryParse(map['end_date'] as String);
    }

    List<int> parsedDaysOfWeek = const [1, 2, 3, 4, 5, 6, 7];
    if (map['days_of_week'] != null) {
      try {
        final decoded = jsonDecode(map['days_of_week'] as String);
        if (decoded is List) {
          parsedDaysOfWeek = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'Health',
      trackingType: (map['tracking_type'] as String?) ?? 'boolean',
      targetValue: (map['target_value'] as num?)?.toDouble() ?? 1.0,
      unit: (map['unit'] as String?) ?? 'times',
      frequency: (map['frequency'] as String?) ?? 'daily',
      daysOfWeek: parsedDaysOfWeek,
      timeOfDay: (map['time_of_day'] as String?) ?? 'all',
      priority: (map['priority'] as String?) ?? 'medium',
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      icon: (map['icon'] as String?) ?? 'bolt',
      color: (map['color'] as int?) ?? 0xFF6366F1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class HabitLog {
  final String id;
  final String habitId;
  final String dateStr; // YYYY-MM-DD
  final double value;
  final bool isCompleted;
  final HabitDayStatus status;
  final String? notes;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.dateStr,
    required this.value,
    required this.isCompleted,
    HabitDayStatus? status,
    this.notes,
  }) : status = status ?? (isCompleted ? HabitDayStatus.done : HabitDayStatus.pending);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date_str': dateStr,
      'value': value,
      'is_completed': isCompleted ? 1 : 0,
      'status': status.dbValue,
      'notes': notes,
    };
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    final isDone = (map['is_completed'] as int? ?? 0) == 1;
    final statusStr = map['status'] as String?;
    final status = statusStr != null
        ? HabitDayStatus.fromDbValue(statusStr)
        : (isDone ? HabitDayStatus.done : HabitDayStatus.pending);

    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      dateStr: map['date_str'] as String,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      isCompleted: isDone,
      status: status,
      notes: map['notes'] as String?,
    );
  }
}
