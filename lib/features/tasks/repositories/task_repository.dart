import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/task.dart';
import '../models/recurrence_engine.dart';

class TaskRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  TaskRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<TaskItem>> getTasks({
    String? status, // 'inbox', 'today', 'upcoming', 'completed', 'all'
    TaskPriority? priority,
    String? projectId,
    String? roadmapTopicId,
  }) async {
    final db = await _db;
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (status != null) {
      if (status == 'inbox') {
        whereClause += " AND status = 'inbox'";
      } else if (status == 'today') {
        whereClause += " AND status != 'completed' AND status != 'cancelled' AND due_date LIKE ?";
        whereArgs.add('$todayStr%');
      } else if (status == 'upcoming') {
        whereClause += " AND status != 'completed' AND status != 'cancelled' AND due_date > ?";
        whereArgs.add('${todayStr}T23:59:59');
      } else if (status == 'completed') {
        whereClause += " AND status = 'completed'";
      } else if (status == 'pending') {
        whereClause += " AND status != 'completed' AND status != 'cancelled'";
      }
    }

    if (priority != null) {
      whereClause += ' AND priority = ?';
      whereArgs.add(priority.name);
    }

    if (projectId != null) {
      whereClause += ' AND project_id = ?';
      whereArgs.add(projectId);
    }

    if (roadmapTopicId != null) {
      whereClause += ' AND roadmap_topic_id = ?';
      whereArgs.add(roadmapTopicId);
    }

    final rows = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'is_top_priority DESC, due_date ASC, created_at DESC',
    );

    final List<TaskItem> tasks = [];
    for (final row in rows) {
      final subtasksRows = await db.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      final subtasks = subtasksRows.map((s) => Subtask.fromMap(s)).toList();
      tasks.add(TaskItem.fromMap(row, subtasks: subtasks));
    }
    return tasks;
  }

  Future<List<TaskItem>> getTasksForDate(DateTime date, {String? filter}) async {
    final db = await _db;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    String whereClause;
    List<dynamic> whereArgs = [];

    if (filter == 'inbox') {
      whereClause = "status = 'inbox'";
    } else {
      whereClause = "due_date LIKE ? AND status != 'inbox'";
      whereArgs.add('$dateStr%');

      if (filter == 'completed') {
        whereClause += " AND status = 'completed'";
      } else if (filter == 'pending') {
        whereClause += " AND status != 'completed' AND status != 'cancelled'";
      }
    }

    final rows = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: "is_all_day DESC, CASE WHEN scheduled_time IS NULL OR scheduled_time = '' THEN 1 ELSE 0 END, scheduled_time ASC, is_top_priority DESC, priority DESC, created_at ASC",
    );

    final List<TaskItem> tasks = [];
    final Set<String> directTaskIds = {};
    for (final row in rows) {
      final subtasksRows = await db.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      final subtasks = subtasksRows.map((s) => Subtask.fromMap(s)).toList();
      final t = TaskItem.fromMap(row, subtasks: subtasks);
      tasks.add(t);
      directTaskIds.add(t.id);
    }

    // Include repeating tasks that match this date
    if (filter != 'inbox') {
      final recurringRows = await db.query(
        'tasks',
        where: "recurrence != 'none' AND recurrence != '' AND status != 'cancelled' AND due_date <= ?",
        whereArgs: ['${dateStr}T23:59:59'],
      );

      for (final row in recurringRows) {
        final rootId = row['id'] as String;
        if (directTaskIds.contains(rootId)) continue;

        final subtasksRows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [rootId]);
        final task = TaskItem.fromMap(row, subtasks: subtasksRows.map((s) => Subtask.fromMap(s)).toList());

        if (RecurrenceEngine.occursOnDate(task, date)) {
          if (filter == 'completed' && !task.isCompleted) continue;
          if (filter == 'pending' && task.isCompleted) continue;

          tasks.add(task.copyWith(
            id: '${task.id}_occ_$dateStr',
            dueDate: date,
          ));
        }
      }
    }

    return tasks;
  }

  Future<Set<String>> getTaskDatesForWeek(DateTime startOfWeek, DateTime endOfWeek) async {
    final db = await _db;
    final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
    final endStr = DateFormat('yyyy-MM-dd').format(endOfWeek.add(const Duration(days: 1)));
    final rows = await db.rawQuery(
      "SELECT DISTINCT substr(due_date, 1, 10) as day FROM tasks WHERE due_date >= ? AND due_date < ? AND status != 'cancelled'",
      [startStr, endStr],
    );
    final set = rows.map((r) => r['day'] as String).where((s) => s.isNotEmpty).toSet();

    // Include recurring tasks
    final recurringRows = await db.query(
      'tasks',
      where: "recurrence != 'none' AND recurrence != '' AND status != 'cancelled' AND due_date < ?",
      whereArgs: [endStr],
    );

    for (final row in recurringRows) {
      final task = TaskItem.fromMap(row);
      DateTime cur = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final finish = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);
      while (!cur.isAfter(finish)) {
        if (RecurrenceEngine.occursOnDate(task, cur)) {
          set.add(DateFormat('yyyy-MM-dd').format(cur));
        }
        cur = cur.add(const Duration(days: 1));
      }
    }

    return set;
  }

  Future<List<TaskItem>> getTopPrioritiesForToday() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await db.query(
      'tasks',
      where: "(is_top_priority = 1 OR due_date LIKE ?) AND status != 'completed' AND status != 'cancelled'",
      whereArgs: ['$todayStr%'],
      orderBy: 'is_top_priority DESC, priority DESC',
      limit: 3,
    );

    final List<TaskItem> list = [];
    for (final row in rows) {
      final subtasksRows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [row['id']]);
      list.add(TaskItem.fromMap(row, subtasks: subtasksRows.map((s) => Subtask.fromMap(s)).toList()));
    }
    return list;
  }

  Future<TaskItem?> getTaskById(String id) async {
    final db = await _db;
    final actualId = id.contains('_occ_') ? id.split('_occ_').first : id;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [actualId]);
    if (rows.isEmpty) return null;
    final subtasksRows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [actualId]);
    return TaskItem.fromMap(
      rows.first,
      subtasks: subtasksRows.map((s) => Subtask.fromMap(s)).toList(),
    );
  }

  Future<void> insertTask(TaskItem task) async {
    final db = await _db;
    final taskId = task.id.isEmpty ? _uuid.v4() : task.id;
    final taskToInsert = task.copyWith(id: taskId);

    await db.transaction((txn) async {
      await txn.insert('tasks', taskToInsert.toMap());
      for (final subtask in taskToInsert.subtasks) {
        final subtaskId = subtask.id.isEmpty ? _uuid.v4() : subtask.id;
        await txn.insert('subtasks', subtask.copyWith(id: subtaskId, taskId: taskId).toMap());
      }
    });
  }

  Future<void> updateTask(TaskItem task) async {
    final db = await _db;
    final actualId = task.id.contains('_occ_') ? task.id.split('_occ_').first : task.id;
    final taskToUpdate = task.copyWith(id: actualId);

    await db.transaction((txn) async {
      await txn.update(
        'tasks',
        taskToUpdate.toMap(),
        where: 'id = ?',
        whereArgs: [actualId],
      );
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [actualId]);
      for (final subtask in taskToUpdate.subtasks) {
        final sId = subtask.id.isEmpty ? _uuid.v4() : subtask.id;
        await txn.insert('subtasks', subtask.copyWith(id: sId, taskId: actualId).toMap());
      }
    });
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final db = await _db;
    final status = isCompleted ? TaskStatus.completed.toDbString() : TaskStatus.todo.toDbString();
    final completedAt = isCompleted ? DateTime.now().toIso8601String() : null;
    final actualId = taskId.contains('_occ_') ? taskId.split('_occ_').first : taskId;

    await db.update(
      'tasks',
      {
        'status': status,
        'completed_at': completedAt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [actualId],
    );
  }

  Future<void> toggleSubtaskCompletion(String subtaskId, bool isCompleted) async {
    final db = await _db;
    await db.update(
      'subtasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtaskId],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await _db;
    final actualId = taskId.contains('_occ_') ? taskId.split('_occ_').first : taskId;
    await db.transaction((txn) async {
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [actualId]);
      await txn.delete('tasks', where: 'id = ?', whereArgs: [actualId]);
    });
  }

  Future<List<TaskItem>> getTasksForDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end.add(const Duration(days: 1)));

    final rows = await db.query(
      'tasks',
      where: "status != 'cancelled' AND due_date >= ? AND due_date < ?",
      whereArgs: [startStr, endStr],
      orderBy: 'due_date ASC, is_all_day DESC, scheduled_time ASC',
    );

    final List<TaskItem> tasks = [];
    final Set<String> directKeys = {};
    for (final row in rows) {
      final subtasksRows = await db.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position ASC',
      );
      final subtasks = subtasksRows.map((s) => Subtask.fromMap(s)).toList();
      final t = TaskItem.fromMap(row, subtasks: subtasks);
      tasks.add(t);
      if (t.dueDate != null) {
        directKeys.add('${t.id}_${DateFormat('yyyy-MM-dd').format(t.dueDate!)}');
      }
    }

    // Include recurring tasks across the date range
    final recurringRows = await db.query(
      'tasks',
      where: "recurrence != 'none' AND recurrence != '' AND status != 'cancelled' AND due_date < ?",
      whereArgs: [endStr],
    );

    for (final row in recurringRows) {
      final subtasksRows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [row['id']]);
      final task = TaskItem.fromMap(row, subtasks: subtasksRows.map((s) => Subtask.fromMap(s)).toList());

      DateTime cur = DateTime(start.year, start.month, start.day);
      final finish = DateTime(end.year, end.month, end.day);
      while (!cur.isAfter(finish)) {
        final curStr = DateFormat('yyyy-MM-dd').format(cur);
        final key = '${task.id}_$curStr';
        if (!directKeys.contains(key) && RecurrenceEngine.occursOnDate(task, cur)) {
          tasks.add(task.copyWith(
            id: '${task.id}_occ_$curStr',
            dueDate: cur,
          ));
        }
        cur = cur.add(const Duration(days: 1));
      }
    }

    return tasks;
  }

  Future<List<TaskTemplate>> getTemplates() async {
    final db = await _db;
    final rows = await db.query('task_templates', orderBy: 'created_at DESC');
    return rows.map((r) => TaskTemplate.fromMap(r)).toList();
  }

  Future<void> insertTemplate(TaskTemplate template) async {
    final db = await _db;
    final id = template.id.isEmpty ? _uuid.v4() : template.id;
    await db.insert(
      'task_templates',
      template.toMap()..['id'] = id,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTemplate(String id) async {
    final db = await _db;
    await db.delete('task_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getTodayTaskMetrics() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalRows = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks 
      WHERE (due_date LIKE ? OR completed_at LIKE ?)
    ''', ['$todayStr%', '$todayStr%']);

    final completedRows = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks 
      WHERE status = 'completed' AND (completed_at LIKE ? OR due_date LIKE ?)
    ''', ['$todayStr%', '$todayStr%']);

    final total = Sqflite.firstIntValue(totalRows) ?? 0;
    final completed = Sqflite.firstIntValue(completedRows) ?? 0;

    return {
      'total': total == 0 ? (completed > 0 ? completed : 0) : total,
      'completed': completed,
    };
  }
}

