import '../../../core/models/task.dart';

/// Recurrence Rule Types
enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  monthly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return 'Daily (Every day)';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom...';
    }
  }
}

/// Rich Recurrence Rule specification
class RecurrenceRule {
  final RecurrenceType type;
  final int interval; // e.g. every 1, 2, 3 weeks
  final List<int> daysOfWeek; // 1 = Mon ... 7 = Sun
  final int? dayOfMonth; // 1..31 or -1 for last day
  final DateTime? endDate;

  const RecurrenceRule({
    this.type = RecurrenceType.none,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth,
    this.endDate,
  });

  /// Parse from legacy or custom recurrence string stored in SQLite
  factory RecurrenceRule.fromString(String? raw, {DateTime? endDate}) {
    if (raw == null || raw.isEmpty || raw == 'none') {
      return RecurrenceRule(type: RecurrenceType.none, endDate: endDate);
    }

    final lower = raw.toLowerCase().trim();

    if (lower == 'daily' || lower == 'everyday') {
      return RecurrenceRule(type: RecurrenceType.daily, endDate: endDate);
    }
    if (lower == 'weekdays') {
      return RecurrenceRule(type: RecurrenceType.weekdays, endDate: endDate);
    }
    if (lower == 'weekly') {
      return RecurrenceRule(type: RecurrenceType.weekly, endDate: endDate);
    }
    if (lower == 'monthly') {
      return RecurrenceRule(type: RecurrenceType.monthly, endDate: endDate);
    }
    if (lower == 'yearly') {
      return RecurrenceRule(type: RecurrenceType.yearly, endDate: endDate);
    }

    // Custom format: "weekly:1,3,5" (Mon, Wed, Fri)
    if (lower.startsWith('weekly:')) {
      final parts = lower.substring('weekly:'.length).split(',');
      final days = parts.map((s) => int.tryParse(s.trim())).whereType<int>().toList();
      return RecurrenceRule(
        type: RecurrenceType.weekly,
        daysOfWeek: days,
        endDate: endDate,
      );
    }

    // Custom format: "monthly:6" or "monthly:last"
    if (lower.startsWith('monthly:')) {
      final val = lower.substring('monthly:'.length).trim();
      final day = val == 'last' ? -1 : int.tryParse(val);
      return RecurrenceRule(
        type: RecurrenceType.monthly,
        dayOfMonth: day,
        endDate: endDate,
      );
    }

    // Custom format: "interval:2:days"
    if (lower.startsWith('interval:')) {
      final parts = lower.split(':');
      if (parts.length >= 3) {
        final step = int.tryParse(parts[1]) ?? 1;
        return RecurrenceRule(
          type: RecurrenceType.daily,
          interval: step,
          endDate: endDate,
        );
      }
    }

    return RecurrenceRule(type: RecurrenceType.none, endDate: endDate);
  }

  /// Serialize to string for SQLite storage
  String toDbString() {
    switch (type) {
      case RecurrenceType.none:
        return 'none';
      case RecurrenceType.daily:
        return interval > 1 ? 'interval:$interval:days' : 'daily';
      case RecurrenceType.weekdays:
        return 'weekdays';
      case RecurrenceType.weekly:
        if (daysOfWeek.isNotEmpty) {
          final sorted = List<int>.from(daysOfWeek)..sort();
          return 'weekly:${sorted.join(',')}';
        }
        return 'weekly';
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          return dayOfMonth == -1 ? 'monthly:last' : 'monthly:$dayOfMonth';
        }
        return 'monthly';
      case RecurrenceType.yearly:
        return 'yearly';
      case RecurrenceType.custom:
        return 'daily';
    }
  }

  String get summaryLabel {
    switch (type) {
      case RecurrenceType.none:
        return 'Does not repeat';
      case RecurrenceType.daily:
        return interval > 1 ? 'Every $interval days' : 'Every day';
      case RecurrenceType.weekdays:
        return 'Every weekday (Mon–Fri)';
      case RecurrenceType.weekly:
        if (daysOfWeek.isNotEmpty) {
          const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dayNames = daysOfWeek.map((d) => names[d]).join(', ');
          return 'Weekly on $dayNames';
        }
        return 'Weekly';
      case RecurrenceType.monthly:
        if (dayOfMonth != null) {
          return dayOfMonth == -1 ? 'Monthly on the last day' : 'Monthly on day $dayOfMonth';
        }
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }
}

/// Evaluator engine for repeating tasks
class RecurrenceEngine {
  /// Format readable description of recurrence rule
  static String formatDescription(TaskItem task) {
    final rule = RecurrenceRule.fromString(task.recurrence, endDate: task.recurrenceEndDate);
    String desc = rule.summaryLabel;
    if (task.recurrenceEndDate != null) {
      desc += ' until ${task.recurrenceEndDate!.month}/${task.recurrenceEndDate!.day}/${task.recurrenceEndDate!.year}';
    }
    return desc;
  }

  /// Checks whether a task occurs on a specific [targetDate]
  static bool occursOnDate(TaskItem task, DateTime targetDate) {
    if (task.dueDate == null) return false;
    if (task.recurrence == 'none' || task.recurrence.isEmpty) {
      final s = task.dueDate!;
      return s.year == targetDate.year && s.month == targetDate.month && s.day == targetDate.day;
    }

    final start = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // Cannot occur before start date
    if (target.isBefore(start)) return false;

    // Check repeat end date constraint
    if (task.recurrenceEndDate != null) {
      final end = DateTime(
        task.recurrenceEndDate!.year,
        task.recurrenceEndDate!.month,
        task.recurrenceEndDate!.day,
        23,
        59,
        59,
      );
      if (target.isAfter(end)) return false;
    }

    final rule = RecurrenceRule.fromString(task.recurrence, endDate: task.recurrenceEndDate);

    switch (rule.type) {
      case RecurrenceType.none:
        return target.isAtSameMomentAs(start);

      case RecurrenceType.daily:
        if (rule.interval <= 1) return true;
        final diffDays = target.difference(start).inDays;
        return diffDays % rule.interval == 0;

      case RecurrenceType.weekdays:
        return target.weekday >= DateTime.monday && target.weekday <= DateTime.friday;

      case RecurrenceType.weekly:
        if (rule.daysOfWeek.isNotEmpty) {
          return rule.daysOfWeek.contains(target.weekday);
        }
        // Defaults to same weekday as start date
        return target.weekday == start.weekday;

      case RecurrenceType.monthly:
        final targetDayOfMonth = rule.dayOfMonth ?? start.day;
        final lastDayOfTargetMonth = DateTime(target.year, target.month + 1, 0).day;

        if (targetDayOfMonth == -1) {
          return target.day == lastDayOfTargetMonth;
        }

        // Clamp to last day if month has fewer days (e.g. 31 in Feb -> 28/29)
        final effectiveDay = targetDayOfMonth > lastDayOfTargetMonth ? lastDayOfTargetMonth : targetDayOfMonth;
        return target.day == effectiveDay;

      case RecurrenceType.yearly:
        return target.month == start.month && target.day == start.day;

      case RecurrenceType.custom:
        return false;
    }
  }

  /// Calculates the next occurrence after [fromDate]
  static DateTime? getNextOccurrence(TaskItem task, DateTime fromDate) {
    if (task.dueDate == null) return null;
    DateTime probe = fromDate.add(const Duration(days: 1));
    final limit = probe.add(const Duration(days: 366 * 2)); // look ahead up to 2 years

    while (probe.isBefore(limit)) {
      if (occursOnDate(task, probe)) {
        return probe;
      }
      probe = probe.add(const Duration(days: 1));
    }
    return null;
  }
}
