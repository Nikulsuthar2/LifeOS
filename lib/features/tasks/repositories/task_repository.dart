import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/task.dart';

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
        whereClause += " AND (status != 'completed' AND status != 'cancelled' AND (due_date LIKE ? OR is_top_priority = 1))";
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
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final subtasksRows = await db.query('subtasks', where: 'task_id = ?', whereArgs: [id]);
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
    await db.transaction((txn) async {
      await txn.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [task.id]);
      for (final subtask in task.subtasks) {
        final sId = subtask.id.isEmpty ? _uuid.v4() : subtask.id;
        await txn.insert('subtasks', subtask.copyWith(id: sId, taskId: task.id).toMap());
      }
    });
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final db = await _db;
    final status = isCompleted ? TaskStatus.completed.toDbString() : TaskStatus.todo.toDbString();
    final completedAt = isCompleted ? DateTime.now().toIso8601String() : null;

    await db.update(
      'tasks',
      {
        'status': status,
        'completed_at': completedAt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
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
    await db.transaction((txn) async {
      await txn.delete('subtasks', where: 'task_id = ?', whereArgs: [taskId]);
      await txn.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
    });
  }

  Future<Map<String, int>> getTodayTaskMetrics() async {
    final db = await _db;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalRows = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks 
      WHERE (due_date LIKE ? OR is_top_priority = 1 OR completed_at LIKE ?)
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

