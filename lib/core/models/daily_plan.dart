class ScheduleBlock {
  final String id;
  final String? taskId;
  final String title;
  final String startTime; // "07:00"
  final String endTime;   // "07:30"
  final String dateStr;   // "2026-11-12"
  final bool isCompleted;

  ScheduleBlock({
    required this.id,
    this.taskId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.dateStr,
    this.isCompleted = false,
  });

  ScheduleBlock copyWith({
    String? id,
    String? taskId,
    String? title,
    String? startTime,
    String? endTime,
    String? dateStr,
    bool? isCompleted,
  }) {
    return ScheduleBlock(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dateStr: dateStr ?? this.dateStr,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'date_str': dateStr,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory ScheduleBlock.fromMap(Map<String, dynamic> map) {
    return ScheduleBlock(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      title: map['title'] as String,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      dateStr: map['date_str'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }
}

