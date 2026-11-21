import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/gamification.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

class GamificationRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;
  final _uuid = const Uuid();

  Future<GamificationProfile> getProfile() async {
    final db = await _db;
    final rows = await db.query('gamification_profile', limit: 1);
    if (rows.isEmpty) {
      final defaultProfile = GamificationProfile(
        id: 'main_user_profile',
        updatedAt: DateTime.now(),
      );
      await db.insert('gamification_profile', defaultProfile.toMap());
      return defaultProfile;
    }
    return GamificationProfile.fromMap(rows.first);
  }

  Future<List<GamificationBadge>> getBadges() async {
    final db = await _db;
    final rows = await db.query('gamification_badges', orderBy: 'unlocked_at DESC, id ASC');
    return rows.map((r) => GamificationBadge.fromMap(r)).toList();
  }

  Future<List<GamificationXpLog>> getXpLogs({int limit = 30}) async {
    final db = await _db;
    final rows = await db.query('gamification_xp_logs', orderBy: 'created_at DESC', limit: limit);
    return rows.map((r) => GamificationXpLog.fromMap(r)).toList();
  }

  Future<GamificationProfile> awardXp(int amount, String module, String reason) async {
    final db = await _db;
    final profile = await getProfile();

    // 1. Log the XP transaction
    final log = GamificationXpLog(
      id: _uuid.v4(),
      amount: amount,
      sourceModule: module,
      reason: reason,
      createdAt: DateTime.now(),
    );
    await db.insert('gamification_xp_logs', log.toMap());

    // 2. Calculate Total XP & Level Up
    final newTotalXp = profile.totalXp + amount;
    final newLevel = (newTotalXp ~/ 100) + 1;
    var newFreezes = profile.streakFreezes;

    if (newLevel > profile.currentLevel) {
      // Award extra streak freeze on level up
      newFreezes += 1;
    }

    final updated = profile.copyWith(
      totalXp: newTotalXp,
      currentLevel: newLevel,
      streakFreezes: newFreezes,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'gamification_profile',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );

    // 3. Check Badge unlocks
    await _checkAndUnlockBadges(db, updated);

    return updated;
  }

  Future<void> _checkAndUnlockBadges(Database db, GamificationProfile profile) async {
    final nowStr = DateTime.now().toIso8601String();

    // First Step badge
    if (profile.totalXp > 0) {
      await db.update(
        'gamification_badges',
        {'unlocked_at': nowStr},
        where: "code = 'first_task' AND unlocked_at IS NULL",
      );
    }

    // Polymath Lv 3+ badge
    if (profile.currentLevel >= 3) {
      await db.update(
        'gamification_badges',
        {'unlocked_at': nowStr},
        where: "code = 'polymath_init' AND unlocked_at IS NULL",
      );
    }

    // Deep focus badge
    if (profile.totalXp >= 200) {
      await db.update(
        'gamification_badges',
        {'unlocked_at': nowStr},
        where: "code = 'deep_focus' AND unlocked_at IS NULL",
      );
    }
  }

  Future<bool> useStreakFreeze() async {
    final db = await _db;
    final profile = await getProfile();
    if (profile.streakFreezes <= 0) return false;

    await db.update(
      'gamification_profile',
      {'streak_freezes': profile.streakFreezes - 1},
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    return true;
  }

  /// Composite daily Life Score (0–100%)
  Future<int> getDailyLifeScore(DateTime date) async {
    final db = await _db;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    double score = 0;

    // 1. Tasks completion (max 30 pts)
    final tasks = await db.rawQuery(
      "SELECT count(*) as total, SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as done FROM tasks WHERE due_date LIKE ? AND status != 'cancelled'",
      ['$dateStr%'],
    );
    final totalTasks = (tasks.first['total'] as int?) ?? 0;
    final doneTasks = (tasks.first['done'] as int?) ?? 0;
    if (totalTasks > 0) {
      score += (doneTasks / totalTasks) * 30;
    } else {
      score += 20; // Default baseline if no tasks scheduled
    }

    // 2. Habits completed (max 30 pts)
    final habits = await db.rawQuery(
      "SELECT count(*) as count FROM habit_logs WHERE date_str = ? AND status = 'done'",
      [dateStr],
    );
    final doneHabits = (habits.first['count'] as int?) ?? 0;
    if (doneHabits >= 3) {
      score += 30;
    } else {
      score += (doneHabits * 10);
    }

    // 3. Water intake (max 15 pts)
    final water = await db.query('health_water_logs', where: 'date_str = ?', whereArgs: [dateStr]);
    if (water.isNotEmpty) {
      final glasses = (water.first['glasses_drank'] as int?) ?? 0;
      final target = (water.first['target_glasses'] as int?) ?? 8;
      score += ((glasses / target).clamp(0.0, 1.0)) * 15;
    }

    // 4. Journal / Reflection logged (max 15 pts)
    final journal = await db.query('journal_entries', where: 'date_str = ?', whereArgs: [dateStr]);
    if (journal.isNotEmpty) {
      score += 15;
    }

    // 5. Sleep logged (max 10 pts)
    final sleep = await db.query('health_sleep_logs', where: 'date_str = ?', whereArgs: [dateStr]);
    if (sleep.isNotEmpty) {
      score += 10;
    }

    return score.round().clamp(0, 100);
  }

  /// Activity counts for last [days] days for GitHub-style heatmap
  Future<Map<String, int>> getActivityHeatmap({int days = 84}) async {
    final db = await _db;
    final Map<String, int> heatmap = {};

    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      heatmap[DateFormat('yyyy-MM-dd').format(d)] = 0;
    }

    final startDateStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: days)));

    // Aggregate tasks completed
    final tasksRows = await db.rawQuery(
      "SELECT substr(completed_at, 1, 10) as day, count(*) as count FROM tasks WHERE status = 'completed' AND completed_at >= ? GROUP BY day",
      [startDateStr],
    );
    for (final row in tasksRows) {
      final day = row['day'] as String?;
      final count = row['count'] as int? ?? 0;
      if (day != null && heatmap.containsKey(day)) {
        heatmap[day] = (heatmap[day] ?? 0) + count;
      }
    }

    // Aggregate habits done
    final habitRows = await db.rawQuery(
      "SELECT date_str, count(*) as count FROM habit_logs WHERE status = 'done' AND date_str >= ? GROUP BY date_str",
      [startDateStr],
    );
    for (final row in habitRows) {
      final day = row['date_str'] as String?;
      final count = row['count'] as int? ?? 0;
      if (day != null && heatmap.containsKey(day)) {
        heatmap[day] = (heatmap[day] ?? 0) + count;
      }
    }

    // Aggregate journal entries
    final journalRows = await db.rawQuery(
      "SELECT date_str, count(*) as count FROM journal_entries WHERE date_str >= ? GROUP BY date_str",
      [startDateStr],
    );
    for (final row in journalRows) {
      final day = row['date_str'] as String?;
      final count = row['count'] as int? ?? 0;
      if (day != null && heatmap.containsKey(day)) {
        heatmap[day] = (heatmap[day] ?? 0) + count;
      }
    }

    // Aggregate workouts
    final workoutRows = await db.rawQuery(
      "SELECT date_str, count(*) as count FROM health_workouts WHERE date_str >= ? GROUP BY date_str",
      [startDateStr],
    );
    for (final row in workoutRows) {
      final day = row['date_str'] as String?;
      final count = row['count'] as int? ?? 0;
      if (day != null && heatmap.containsKey(day)) {
        heatmap[day] = (heatmap[day] ?? 0) + count;
      }
    }

    return heatmap;
  }
}
