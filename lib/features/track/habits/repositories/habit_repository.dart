import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/habit.dart';

class HabitWithStatus {
  final Habit habit;
  final HabitLog? todayLog;
  final HabitDayStatus todayStatus;
  final int streakDays;
  final int bestStreakDays;
  final List<DateTime> weekDays; // 7 days Mon - Sun of the selected week
  final List<HabitDayStatus> weekStatuses; // 3-state statuses for each of the 7 days
  final List<bool> weekDayEnabled; // is that day scheduled AND unlocked (day <= today)
  final List<bool> weekDayScheduled; // is that day scheduled according to habit frequency & range
  final int weekCompletedCount; // completed days up to today
  final int weekEnabledCount; // eligible days up to today
  final int weekPercentage;

  HabitWithStatus({
    required this.habit,
    this.todayLog,
    required this.todayStatus,
    required this.streakDays,
    required this.bestStreakDays,
    required this.weekDays,
    required this.weekStatuses,
    required this.weekDayEnabled,
    List<bool>? weekDayScheduled,
    required this.weekCompletedCount,
    required this.weekEnabledCount,
    required this.weekPercentage,
  }) : weekDayScheduled = weekDayScheduled ?? weekDayEnabled;

  bool get isCompletedToday => todayStatus == HabitDayStatus.done;
  double get todayProgress => (todayLog?.value ?? 0.0) / (habit.targetValue > 0 ? habit.targetValue : 1.0);
  List<bool> get last7Days => weekStatuses.map((s) => s == HabitDayStatus.done).toList();
}

class HabitTimelinePoint {
  final String label;
  final int completed;
  final int failed;
  final int total;
  final DateTime date;

  HabitTimelinePoint({
    required this.label,
    required this.completed,
    required this.failed,
    required this.total,
    required this.date,
  });
}

class HabitDetailedStats {
  final Habit habit;
  final int overallScorePercentage;
  final int currentStreak;
  final int bestStreak;
  final int timesCompletedThisWeek;
  final int timesCompletedThisMonth;
  final int timesCompletedThisYear;
  final int timesCompletedAllTime;
  final int totalFailedAllTime;
  final int totalPendingAllTime;
  final int totalDaysTracked;
  final List<HabitTimelinePoint> timeline;

  HabitDetailedStats({
    required this.habit,
    required this.overallScorePercentage,
    required this.currentStreak,
    required this.bestStreak,
    required this.timesCompletedThisWeek,
    required this.timesCompletedThisMonth,
    required this.timesCompletedThisYear,
    required this.timesCompletedAllTime,
    required this.totalFailedAllTime,
    required this.totalPendingAllTime,
    required this.totalDaysTracked,
    required this.timeline,
  });
}

class HabitMonthResult {
  final Map<String, HabitDayStatus> dayStatuses;
  final int highestStreak;
  final int completedCount;
  final int failedCount;
  final int pendingCount;

  HabitMonthResult({
    required this.dayStatuses,
    required this.highestStreak,
    required this.completedCount,
    required this.failedCount,
    required this.pendingCount,
  });
}

class HabitRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  HabitRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  /// Check whether a specific date is scheduled for a habit (frequency, start/end date)
  bool isDayScheduled(Habit habit, DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final startOnly = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
    if (dayOnly.isBefore(startOnly)) return false;

    if (habit.endDate != null) {
      final endOnly = DateTime(habit.endDate!.year, habit.endDate!.month, habit.endDate!.day);
      if (dayOnly.isAfter(endOnly)) return false;
    }

    if (habit.frequency == 'specific_days' || habit.daysOfWeek.length < 7) {
      if (!habit.daysOfWeek.contains(day.weekday)) return false;
    }

    return true;
  }

  /// Check whether a specific date is scheduled AND unlocked (day <= today)
  bool isDayEnabled(Habit habit, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    if (dayOnly.isAfter(today)) return false;
    return isDayScheduled(habit, day);
  }

  Future<List<HabitWithStatus>> getHabitsWithStatus({DateTime? weekDate}) async {
    final db = await _db;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final targetDate = weekDate ?? today;
    final targetMonday = DateTime(targetDate.year, targetDate.month, targetDate.day)
        .subtract(Duration(days: targetDate.weekday - 1));

    // 7 days Mon - Sun of the selected week
    final weekDays = List.generate(7, (i) => targetMonday.add(Duration(days: i)));

    final habitRows = await db.query(
      'habits',
      where: 'is_archived = 0',
      orderBy: 'created_at ASC',
    );

    final List<HabitWithStatus> result = [];

    for (final hRow in habitRows) {
      final habit = Habit.fromMap(hRow);

      // Today's log
      final todayLogRows = await db.query(
        'habit_logs',
        where: 'habit_id = ? AND date_str = ?',
        whereArgs: [habit.id, todayStr],
      );
      final todayLog = todayLogRows.isNotEmpty ? HabitLog.fromMap(todayLogRows.first) : null;
      final todayStatus = todayLog?.status ?? HabitDayStatus.pending;

      // 7 Days of selected week
      final List<HabitDayStatus> weekStatuses = [];
      final List<bool> weekDayEnabled = [];
      final List<bool> weekDayScheduled = [];
      int weekCompleted = 0;
      int weekEnabled = 0;

      for (final day in weekDays) {
        final dStr = DateFormat('yyyy-MM-dd').format(day);
        final isScheduled = isDayScheduled(habit, day);
        final isUnlocked = isDayEnabled(habit, day);

        weekDayScheduled.add(isScheduled);
        weekDayEnabled.add(isUnlocked);
        if (isUnlocked) weekEnabled++;

        final dLogRows = await db.query(
          'habit_logs',
          where: 'habit_id = ? AND date_str = ?',
          whereArgs: [habit.id, dStr],
        );

        if (dLogRows.isNotEmpty) {
          final log = HabitLog.fromMap(dLogRows.first);
          weekStatuses.add(log.status);
          if (isUnlocked && log.status == HabitDayStatus.done) {
            weekCompleted++;
          }
        } else {
          weekStatuses.add(HabitDayStatus.pending);
        }
      }

      final weekPct = weekEnabled > 0 ? ((weekCompleted / weekEnabled) * 100).round() : 0;

      // Calculate current streak & best streak
      final allLogs = await db.query(
        'habit_logs',
        where: 'habit_id = ?',
        whereArgs: [habit.id],
        orderBy: 'date_str ASC',
      );

      final Map<String, HabitDayStatus> logsMap = {};
      for (final row in allLogs) {
        final log = HabitLog.fromMap(row);
        logsMap[log.dateStr] = log.status;
      }

      int currentStreak = 0;
      int checkOffset = todayStatus == HabitDayStatus.done ? 0 : 1;
      while (true) {
        final checkDay = today.subtract(Duration(days: checkOffset));
        if (!isDayScheduled(habit, checkDay)) {
          // If habit was not scheduled on this day, skip without breaking streak
          checkOffset++;
          if (checkOffset > 365) break;
          continue;
        }

        final checkDateStr = DateFormat('yyyy-MM-dd').format(checkDay);
        final status = logsMap[checkDateStr] ?? HabitDayStatus.pending;
        if (status == HabitDayStatus.done) {
          currentStreak++;
          checkOffset++;
        } else {
          break;
        }
      }

      // Best streak calculation
      int bestStreak = currentStreak;
      int runningStreak = 0;
      final startOnly = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
      final daysSinceStart = today.difference(startOnly).inDays.clamp(0, 730);

      for (int i = daysSinceStart; i >= 0; i--) {
        final d = startOnly.add(Duration(days: i));
        if (!isDayScheduled(habit, d)) continue;
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        final status = logsMap[dStr] ?? HabitDayStatus.pending;
        if (status == HabitDayStatus.done) {
          runningStreak++;
          if (runningStreak > bestStreak) bestStreak = runningStreak;
        } else if (status == HabitDayStatus.fail || (status == HabitDayStatus.pending && d.isBefore(today))) {
          runningStreak = 0;
        }
      }

      result.add(HabitWithStatus(
        habit: habit,
        todayLog: todayLog,
        todayStatus: todayStatus,
        streakDays: currentStreak,
        bestStreakDays: bestStreak,
        weekDays: weekDays,
        weekStatuses: weekStatuses,
        weekDayEnabled: weekDayEnabled,
        weekDayScheduled: weekDayScheduled,
        weekCompletedCount: weekCompleted,
        weekEnabledCount: weekEnabled,
        weekPercentage: weekPct,
      ));
    }

    return result;
  }

  /// Cycle status for a specific date: pending -> done -> fail -> pending
  Future<HabitDayStatus> cycleHabitDayStatus(String habitId, String dateStr) async {
    final db = await _db;
    final existing = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date_str = ?',
      whereArgs: [habitId, dateStr],
    );

    HabitDayStatus currentStatus = HabitDayStatus.pending;
    if (existing.isNotEmpty) {
      currentStatus = HabitDayStatus.fromDbValue(existing.first['status'] as String?);
    }

    final nextStatus = currentStatus.next;

    if (existing.isEmpty) {
      final hRow = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      final target = hRow.isNotEmpty ? ((hRow.first['target_value'] as num?)?.toDouble() ?? 1.0) : 1.0;

      await db.insert('habit_logs', {
        'id': _uuid.v4(),
        'habit_id': habitId,
        'date_str': dateStr,
        'value': nextStatus == HabitDayStatus.done ? target : 0.0,
        'is_completed': nextStatus == HabitDayStatus.done ? 1 : 0,
        'status': nextStatus.dbValue,
      });
    } else {
      final logId = existing.first['id'] as String;
      final hRow = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      final target = hRow.isNotEmpty ? ((hRow.first['target_value'] as num?)?.toDouble() ?? 1.0) : 1.0;

      await db.update(
        'habit_logs',
        {
          'status': nextStatus.dbValue,
          'is_completed': nextStatus == HabitDayStatus.done ? 1 : 0,
          'value': nextStatus == HabitDayStatus.done ? target : 0.0,
        },
        where: 'id = ?',
        whereArgs: [logId],
      );
    }

    return nextStatus;
  }

  /// Explicitly set status for a specific date
  Future<void> setHabitDayStatus(String habitId, String dateStr, HabitDayStatus status) async {
    final db = await _db;
    final existing = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date_str = ?',
      whereArgs: [habitId, dateStr],
    );

    final hRow = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    final target = hRow.isNotEmpty ? ((hRow.first['target_value'] as num?)?.toDouble() ?? 1.0) : 1.0;

    if (existing.isEmpty) {
      await db.insert('habit_logs', {
        'id': _uuid.v4(),
        'habit_id': habitId,
        'date_str': dateStr,
        'value': status == HabitDayStatus.done ? target : 0.0,
        'is_completed': status == HabitDayStatus.done ? 1 : 0,
        'status': status.dbValue,
      });
    } else {
      final logId = existing.first['id'] as String;
      await db.update(
        'habit_logs',
        {
          'status': status.dbValue,
          'is_completed': status == HabitDayStatus.done ? 1 : 0,
          'value': status == HabitDayStatus.done ? target : 0.0,
        },
        where: 'id = ?',
        whereArgs: [logId],
      );
    }
  }

  /// Backward compatible toggle method
  Future<void> toggleHabitCompletion(String habitId, {double? customValue}) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await cycleHabitDayStatus(habitId, todayStr);
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await _db;
    final hId = habit.id.isEmpty ? _uuid.v4() : habit.id;
    await db.insert('habits', habit.copyWith(id: hId).toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _db;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Reset all logs for this habit and set start date to today
  Future<void> restartHabitProgress(String habitId) async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
      await txn.update(
        'habits',
        {'start_date': todayStr},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    });
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
  }

  Future<Habit?> getHabitById(String habitId) async {
    final db = await _db;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
    if (rows.isEmpty) return null;
    return Habit.fromMap(rows.first);
  }

  /// Get month logs and calculate highest streak in that month
  Future<HabitMonthResult> getMonthLogs(String habitId, int year, int month) async {
    final db = await _db;
    final habit = await getHabitById(habitId);
    if (habit == null) {
      return HabitMonthResult(
        dayStatuses: {},
        highestStreak: 0,
        completedCount: 0,
        failedCount: 0,
        pendingCount: 0,
      );
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startStr = '$year-${month.toString().padLeft(2, '0')}-01';
    final endStr = '$year-${month.toString().padLeft(2, '0')}-${daysInMonth.toString().padLeft(2, '0')}';

    final logRows = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date_str >= ? AND date_str <= ?',
      whereArgs: [habitId, startStr, endStr],
    );

    final Map<String, HabitDayStatus> statuses = {};
    for (final row in logRows) {
      final log = HabitLog.fromMap(row);
      statuses[log.dateStr] = log.status;
    }

    int highestStreak = 0;
    int currentRunning = 0;
    int completedCount = 0;
    int failedCount = 0;
    int pendingCount = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(year, month, day);
      final dStr = DateFormat('yyyy-MM-dd').format(dt);
      final status = statuses[dStr] ?? HabitDayStatus.pending;

      if (status == HabitDayStatus.done) {
        completedCount++;
        currentRunning++;
        if (currentRunning > highestStreak) highestStreak = currentRunning;
      } else if (status == HabitDayStatus.fail) {
        failedCount++;
        currentRunning = 0;
      } else {
        pendingCount++;
        if (isDayEnabled(habit, dt)) {
          currentRunning = 0;
        }
      }
    }

    return HabitMonthResult(
      dayStatuses: statuses,
      highestStreak: highestStreak,
      completedCount: completedCount,
      failedCount: failedCount,
      pendingCount: pendingCount,
    );
  }

  /// Get detailed stats for habit
  Future<HabitDetailedStats> getHabitDetailedStats(String habitId, {String period = 'week'}) async {
    final db = await _db;
    final habit = await getHabitById(habitId);
    if (habit == null) {
      throw Exception('Habit $habitId not found');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Query all logs
    final logs = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'date_str ASC',
    );

    final Map<String, HabitDayStatus> logsMap = {};
    int timesDoneAllTime = 0;
    int totalFailAllTime = 0;

    for (final row in logs) {
      final log = HabitLog.fromMap(row);
      logsMap[log.dateStr] = log.status;
      if (log.status == HabitDayStatus.done) timesDoneAllTime++;
      if (log.status == HabitDayStatus.fail) totalFailAllTime++;
    }

    // This week (Mon - Sun)
    final monday = today.subtract(Duration(days: today.weekday - 1));
    int timesDoneWeek = 0;
    for (int i = 0; i < 7; i++) {
      final dStr = DateFormat('yyyy-MM-dd').format(monday.add(Duration(days: i)));
      if (logsMap[dStr] == HabitDayStatus.done) timesDoneWeek++;
    }

    // This month
    final startOfMonth = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    int timesDoneMonth = 0;
    for (int i = 0; i < daysInMonth; i++) {
      final dStr = DateFormat('yyyy-MM-dd').format(startOfMonth.add(Duration(days: i)));
      if (logsMap[dStr] == HabitDayStatus.done) timesDoneMonth++;
    }

    // This year
    final startOfYear = DateTime(today.year, 1, 1);
    final daysInYear = DateTime(today.year + 1, 1, 0).difference(startOfYear).inDays;
    int timesDoneYear = 0;
    for (int i = 0; i < daysInYear; i++) {
      final dStr = DateFormat('yyyy-MM-dd').format(startOfYear.add(Duration(days: i)));
      if (logsMap[dStr] == HabitDayStatus.done) timesDoneYear++;
    }

    // Current Streak & Best Streak
    int currentStreak = 0;
    final todayDone = logsMap[todayStr] == HabitDayStatus.done;
    int checkOffset = todayDone ? 0 : 1;
    while (true) {
      final checkDay = today.subtract(Duration(days: checkOffset));
      if (!isDayEnabled(habit, checkDay)) {
        checkOffset++;
        if (checkOffset > 365) break;
        continue;
      }
      final dStr = DateFormat('yyyy-MM-dd').format(checkDay);
      if (logsMap[dStr] == HabitDayStatus.done) {
        currentStreak++;
        checkOffset++;
      } else {
        break;
      }
    }

    // All active days calculation
    DateTime effectiveStartDate = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);

    // If the habit has logs, ensure effectiveStartDate does not precede the earliest log date
    // if the configured startDate was artificially earlier with no logs in between.
    if (logs.isNotEmpty) {
      final earliestLogStr = logs.first['date_str'] as String?;
      if (earliestLogStr != null && earliestLogStr.isNotEmpty) {
        final earliestLogDate = DateTime.tryParse(earliestLogStr);
        if (earliestLogDate != null) {
          final earliestLogOnly = DateTime(earliestLogDate.year, earliestLogDate.month, earliestLogDate.day);
          if (effectiveStartDate.isBefore(earliestLogOnly)) {
            effectiveStartDate = earliestLogOnly;
          }
        }
      }
    } else {
      // If no logs exist yet, clamp start to today so new habits don't count unlogged past days
      if (effectiveStartDate.isBefore(today)) {
        effectiveStartDate = today;
      }
    }

    final endLimit = habit.endDate != null && habit.endDate!.isBefore(today)
        ? DateTime(habit.endDate!.year, habit.endDate!.month, habit.endDate!.day)
        : today;

    int totalActiveDays = 0;
    int totalDoneInActiveRange = 0;
    int runningStreak = 0;
    int bestStreak = currentStreak;

    final totalSpan = endLimit.difference(effectiveStartDate).inDays.clamp(0, 730);
    for (int i = 0; i <= totalSpan; i++) {
      final d = effectiveStartDate.add(Duration(days: i));
      if (!isDayEnabled(habit, d)) continue;
      totalActiveDays++;

      final dStr = DateFormat('yyyy-MM-dd').format(d);
      final st = logsMap[dStr] ?? HabitDayStatus.pending;
      if (st == HabitDayStatus.done) {
        totalDoneInActiveRange++;
        runningStreak++;
        if (runningStreak > bestStreak) bestStreak = runningStreak;
      } else {
        runningStreak = 0;
      }
    }

    final overallScore = totalActiveDays > 0 ? ((totalDoneInActiveRange / totalActiveDays) * 100).round() : 0;
    final totalPendingAllTime = (totalActiveDays - totalDoneInActiveRange - totalFailAllTime).clamp(0, totalActiveDays);

    // Timeline points based on period
    final List<HabitTimelinePoint> timeline = [];
    if (period == 'week') {
      for (int i = 0; i < 7; i++) {
        final d = monday.add(Duration(days: i));
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        final st = logsMap[dStr] ?? HabitDayStatus.pending;
        final enabled = isDayEnabled(habit, d);
        timeline.add(HabitTimelinePoint(
          label: DateFormat('E').format(d).substring(0, 1),
          completed: st == HabitDayStatus.done ? 1 : 0,
          failed: st == HabitDayStatus.fail ? 1 : 0,
          total: enabled ? 1 : 0,
          date: d,
        ));
      }
    } else if (period == 'month') {
      // 4 or 5 weeks of current month
      final totalDays = DateTime(today.year, today.month + 1, 0).day;
      int weekIdx = 1;
      int wCompleted = 0;
      int wFailed = 0;
      int wTotal = 0;

      for (int i = 1; i <= totalDays; i++) {
        final d = DateTime(today.year, today.month, i);
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        final st = logsMap[dStr] ?? HabitDayStatus.pending;
        if (isDayEnabled(habit, d)) wTotal++;
        if (st == HabitDayStatus.done) wCompleted++;
        if (st == HabitDayStatus.fail) wFailed++;

        if (d.weekday == DateTime.sunday || i == totalDays) {
          timeline.add(HabitTimelinePoint(
            label: 'W$weekIdx',
            completed: wCompleted,
            failed: wFailed,
            total: wTotal,
            date: d,
          ));
          weekIdx++;
          wCompleted = 0;
          wFailed = 0;
          wTotal = 0;
        }
      }
    } else {
      // 12 months of current year
      for (int m = 1; m <= 12; m++) {
        final mStart = DateTime(today.year, m, 1);
        final mDays = DateTime(today.year, m + 1, 0).day;
        int mCompleted = 0;
        int mFailed = 0;
        int mTotal = 0;

        for (int day = 1; day <= mDays; day++) {
          final d = DateTime(today.year, m, day);
          final dStr = DateFormat('yyyy-MM-dd').format(d);
          final st = logsMap[dStr] ?? HabitDayStatus.pending;
          if (isDayEnabled(habit, d)) mTotal++;
          if (st == HabitDayStatus.done) mCompleted++;
          if (st == HabitDayStatus.fail) mFailed++;
        }

        timeline.add(HabitTimelinePoint(
          label: DateFormat('MMM').format(mStart),
          completed: mCompleted,
          failed: mFailed,
          total: mTotal,
          date: mStart,
        ));
      }
    }

    return HabitDetailedStats(
      habit: habit,
      overallScorePercentage: overallScore,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      timesCompletedThisWeek: timesDoneWeek,
      timesCompletedThisMonth: timesDoneMonth,
      timesCompletedThisYear: timesDoneYear,
      timesCompletedAllTime: timesDoneAllTime,
      totalFailedAllTime: totalFailAllTime,
      totalPendingAllTime: totalPendingAllTime,
      totalDaysTracked: totalActiveDays,
      timeline: timeline,
    );
  }

  Future<Map<String, int>> getTodayHabitMetrics() async {
    final habits = await getHabitsWithStatus();
    final total = habits.length;
    final completed = habits.where((h) => h.isCompletedToday).length;
    return {'total': total, 'completed': completed};
  }
}
