import 'package:flutter/material.dart';

class RoutineBlock {
  final String id;
  final String title;
  final String startTime; // "HH:mm" e.g. "06:00"
  final String endTime;   // "HH:mm" e.g. "07:30"
  final String category;  // "Morning", "Deep Work", "Health", "Learning", "Evening", "Sleep", "Rest"
  final int colorValue;
  final String daysOfWeek; // "all", or "1,2,3,4,5"
  final bool isActive;
  final String? notes;

  const RoutineBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.colorValue = 0xFF6366F1,
    this.daysOfWeek = 'all',
    this.isActive = true,
    this.notes,
  });

  Color get color => Color(colorValue);

  /// Helper to calculate duration in minutes
  int get durationMinutes {
    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();
    var startMins = startParts[0] * 60 + startParts[1];
    var endMins = endParts[0] * 60 + endParts[1];
    if (endMins <= startMins) {
      endMins += 24 * 60; // wraps past midnight
    }
    return endMins - startMins;
  }

  /// Check if this routine block is currently happening right now
  bool isNow() {
    final now = DateTime.now();
    final currentMins = now.hour * 60 + now.minute;
    final startParts = startTime.split(':').map(int.parse).toList();
    final endParts = endTime.split(':').map(int.parse).toList();
    final startMins = startParts[0] * 60 + startParts[1];
    final endMins = endParts[0] * 60 + endParts[1];

    if (endMins > startMins) {
      return currentMins >= startMins && currentMins < endMins;
    } else {
      // Over midnight: e.g. 23:00 to 07:00
      return currentMins >= startMins || currentMins < endMins;
    }
  }

  /// Formatted duration string, e.g. "1h 30m"
  String get formattedDuration {
    final mins = durationMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'category': category,
      'color': colorValue,
      'days_of_week': daysOfWeek,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory RoutineBlock.fromMap(Map<String, dynamic> map) {
    return RoutineBlock(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      category: map['category'] as String? ?? 'General',
      colorValue: (map['color'] ?? map['color_value']) as int? ?? 0xFF6366F1,
      daysOfWeek: map['days_of_week'] as String? ?? 'all',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
    );
  }

  RoutineBlock copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    String? category,
    int? colorValue,
    String? daysOfWeek,
    bool? isActive,
    String? notes,
  }) {
    return RoutineBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
