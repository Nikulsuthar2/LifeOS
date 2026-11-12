import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/focus_session.dart';

class DailyFocusMetric {
  final String dateStr;
  final String dayName;
  final int minutes;

  DailyFocusMetric({
    required this.dateStr,
    required this.dayName,
    required this.minutes,
  });
}

class FocusRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  FocusRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<void> saveFocusSession(FocusSession session) async {
    final db = await _db;
    final sessionId = session.id.isEmpty ? _uuid.v4() : session.id;
    final sToInsert = FocusSession(
      id: sessionId,
      title: session.title,
      taskId: session.taskId,
      topicId: session.topicId,
      startedAt: session.startedAt,
      endedAt: session.endedAt ?? DateTime.now(),
      durationSeconds: session.durationSeconds,
      sessionType: session.sessionType,
      notes: session.notes,
      isCompleted: session.isCompleted,
    );

    await db.transaction((txn) async {
      await txn.insert('focus_sessions', sToInsert.toMap());

      final minutes = sToInsert.durationMinutes;

      // Update topic actual_minutes_spent if linked
      if (session.topicId != null && session.topicId!.isNotEmpty) {
        await txn.rawUpdate('''
          UPDATE topics SET actual_minutes_spent = actual_minutes_spent + ? WHERE id = ?
        ''', [minutes, session.topicId]);
      }

      // Update task actual_minutes if linked
      if (session.taskId != null && session.taskId!.isNotEmpty) {
        await txn.rawUpdate('''
          UPDATE tasks SET actual_minutes = actual_minutes + ? WHERE id = ?
        ''', [minutes, session.taskId]);
      }
    });
  }

  Future<int> getTodayFocusMinutes() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final rows = await db.rawQuery('''
      SELECT SUM(duration_seconds) as total_seconds 
      FROM focus_sessions 
      WHERE started_at LIKE ? AND session_type = 'focus' AND is_completed = 1
    ''', ['$todayStr%']);

    final totalSeconds = (rows.first['total_seconds'] as int?) ?? 0;
    return (totalSeconds / 60).round();
  }

  Future<List<DailyFocusMetric>> getWeeklyFocusTrend() async {
    final db = await _db;
    final now = DateTime.now();
    final List<DailyFocusMetric> list = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('E').format(date); // Mon, Tue...

      final rows = await db.rawQuery('''
        SELECT SUM(duration_seconds) as total_seconds 
        FROM focus_sessions 
        WHERE started_at LIKE ? AND session_type = 'focus' AND is_completed = 1
      ''', ['$dateStr%']);

      final totalSeconds = (rows.first['total_seconds'] as int?) ?? 0;
      list.add(DailyFocusMetric(
        dateStr: dateStr,
        dayName: dayName,
        minutes: (totalSeconds / 60).round(),
      ));
    }
    return list;
  }

  Future<List<FocusSession>> getRecentSessions({int limit = 15}) async {
    final db = await _db;
    final rows = await db.query(
      'focus_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map((r) => FocusSession.fromMap(r)).toList();
  }
}

