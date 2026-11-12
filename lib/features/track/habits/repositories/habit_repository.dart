import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/habit.dart';

class HabitWithStatus {
  final Habit habit;
  final HabitLog? todayLog;
  final int streakDays;
  final List<bool> last7Days; // [Mon, Tue, Wed, ...]

  HabitWithStatus({
    required this.habit,
    this.todayLog,
    required this.streakDays,
    required this.last7Days,
  });

  bool get isCompletedToday => todayLog?.isCompleted ?? false;
  double get todayProgress => (todayLog?.value ?? 0.0) / (habit.targetValue > 0 ? habit.targetValue : 1.0);
}

class HabitRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  HabitRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<HabitWithStatus>> getHabitsWithStatus() async {
    final db = await _db;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

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

      // Last 7 days history
      final List<bool> last7Days = [];
      for (int i = 6; i >= 0; i--) {
        final dStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: i)));
        final dLog = await db.query(
          'habit_logs',
          where: 'habit_id = ? AND date_str = ?',
          whereArgs: [habit.id, dStr],
        );
        last7Days.add(dLog.isNotEmpty && ((dLog.first['is_completed'] as int?) ?? 0) == 1);
      }

      // Calculate streak
      int streak = 0;
      int checkOffset = todayLog?.isCompleted == true ? 0 : 1;
      while (true) {
        final checkDateStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: checkOffset)));
        final log = await db.query(
          'habit_logs',
          where: 'habit_id = ? AND date_str = ?',
          whereArgs: [habit.id, checkDateStr],
        );
        if (log.isNotEmpty && ((log.first['is_completed'] as int?) ?? 0) == 1) {
          streak++;
          checkOffset++;
        } else {
          break;
        }
      }

      result.add(HabitWithStatus(
        habit: habit,
        todayLog: todayLog,
        streakDays: streak,
        last7Days: last7Days,
      ));
    }

    return result;
  }

  Future<void> toggleHabitCompletion(String habitId, {double? customValue}) async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final existing = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date_str = ?',
      whereArgs: [habitId, todayStr],
    );

    if (existing.isEmpty) {
      // Habit model to check target value
      final hRow = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      final target = (hRow.first['target_value'] as num?)?.toDouble() ?? 1.0;
      final val = customValue ?? target;

      await db.insert('habit_logs', {
        'id': _uuid.v4(),
        'habit_id': habitId,
        'date_str': todayStr,
        'value': val,
        'is_completed': val >= target ? 1 : 0,
      });
    } else {
      final currentIsCompleted = (existing.first['is_completed'] as int? ?? 0) == 1;
      final nextStatus = !currentIsCompleted;
      final hRow = await db.query('habits', where: 'id = ?', whereArgs: [habitId]);
      final target = (hRow.first['target_value'] as num?)?.toDouble() ?? 1.0;

      await db.update(
        'habit_logs',
        {
          'is_completed': nextStatus ? 1 : 0,
          'value': nextStatus ? target : 0.0,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await _db;
    final hId = habit.id.isEmpty ? _uuid.v4() : habit.id;
    await db.insert('habits', habit.copyWith(id: hId).toMap());
  }

  Future<void> deleteHabit(String habitId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [habitId]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [habitId]);
    });
  }

  Future<Map<String, int>> getTodayHabitMetrics() async {
    final habits = await getHabitsWithStatus();
    final total = habits.length;
    final completed = habits.where((h) => h.isCompletedToday).length;
    return {'total': total, 'completed': completed};
  }
}

