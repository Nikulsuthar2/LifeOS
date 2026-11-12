import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/roadmap.dart';
import '../../../core/models/task.dart';

class RoadmapRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  RoadmapRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<Roadmap>> getRoadmaps() async {
    final db = await _db;
    final roadmapRows = await db.query('roadmaps', orderBy: 'created_at DESC');

    final List<Roadmap> roadmaps = [];
    for (final rRow in roadmapRows) {
      final rId = rRow['id'] as String;
      final stageRows = await db.query(
        'roadmap_stages',
        where: 'roadmap_id = ?',
        whereArgs: [rId],
        orderBy: 'position ASC',
      );

      final List<RoadmapStage> stages = [];
      for (final sRow in stageRows) {
        final sId = sRow['id'] as String;
        final topicRows = await db.query(
          'topics',
          where: 'stage_id = ?',
          whereArgs: [sId],
          orderBy: 'position ASC',
        );

        final List<Topic> topics = [];
        for (final tRow in topicRows) {
          final tId = tRow['id'] as String;
          final lessonRows = await db.query(
            'lessons',
            where: 'topic_id = ?',
            whereArgs: [tId],
            orderBy: 'position ASC',
          );
          final lessons = lessonRows.map((l) => Lesson.fromMap(l)).toList();

          final resourceRows = await db.query(
            'topic_resources',
            where: 'topic_id = ?',
            whereArgs: [tId],
          );
          final resources = resourceRows.map((res) => TopicResource.fromMap(res)).toList();

          topics.add(Topic.fromMap(tRow, lessons: lessons, resources: resources));
        }
        stages.add(RoadmapStage.fromMap(sRow, topics: topics));
      }
      roadmaps.add(Roadmap.fromMap(rRow, stages: stages));
    }
    return roadmaps;
  }

  Future<Roadmap?> getRoadmapById(String id) async {
    final roadmaps = await getRoadmaps();
    try {
      return roadmaps.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveRoadmapSpotlight() async {
    final roadmaps = await getRoadmaps();
    if (roadmaps.isEmpty) return null;

    final activeRoadmap = roadmaps.firstWhere(
      (r) => r.status == 'active',
      orElse: () => roadmaps.first,
    );

    Topic? currentTopic;
    RoadmapStage? currentStage;

    for (final stage in activeRoadmap.stages) {
      for (final topic in stage.topics) {
        if (topic.status == TopicStatus.inProgress) {
          currentTopic = topic;
          currentStage = stage;
          break;
        }
      }
      if (currentTopic != null) break;
    }

    if (currentTopic == null) {
      for (final stage in activeRoadmap.stages) {
        for (final topic in stage.topics) {
          if (topic.status == TopicStatus.available) {
            currentTopic = topic;
            currentStage = stage;
            break;
          }
        }
        if (currentTopic != null) break;
      }
    }

    return {
      'roadmap': activeRoadmap,
      'stage': currentStage,
      'topic': currentTopic,
    };
  }

  Future<void> updateTopicStatus(String topicId, TopicStatus status) async {
    final db = await _db;
    await db.update(
      'topics',
      {'status': status.toDbString()},
      where: 'id = ?',
      whereArgs: [topicId],
    );

    // If completed, unlock dependent topics where prerequisite_topic_id = this topic
    if (status == TopicStatus.completed) {
      await db.update(
        'topics',
        {'status': TopicStatus.available.toDbString()},
        where: "prerequisite_topic_id = ? AND status = 'locked'",
        whereArgs: [topicId],
      );
    }
  }

  Future<void> toggleLessonCompletion(String lessonId, bool isCompleted, String topicId) async {
    final db = await _db;
    await db.update(
      'lessons',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [lessonId],
    );

    // If all lessons in the topic are completed, automatically update topic status to completed
    final remainingLessons = await db.rawQuery('''
      SELECT COUNT(*) as count FROM lessons WHERE topic_id = ? AND is_completed = 0
    ''', [topicId]);
    final remaining = Sqflite.firstIntValue(remainingLessons) ?? 0;

    if (remaining == 0) {
      await updateTopicStatus(topicId, TopicStatus.completed);
    } else {
      // Mark as in progress if available
      final topic = await db.query('topics', where: 'id = ?', whereArgs: [topicId]);
      if (topic.isNotEmpty && topic.first['status'] == 'available') {
        await updateTopicStatus(topicId, TopicStatus.inProgress);
      }
    }
  }

  Future<void> addMinutesToTopic(String topicId, int minutes) async {
    final db = await _db;
    await db.rawUpdate('''
      UPDATE topics SET actual_minutes_spent = actual_minutes_spent + ? WHERE id = ?
    ''', [minutes, topicId]);
  }

  // The killer feature: Generate a Task from a Roadmap Topic
  Future<String> createTaskFromTopic(Topic topic, {String? roadmapTitle}) async {
    final db = await _db;
    final now = DateTime.now();
    final taskId = _uuid.v4();

    final task = TaskItem(
      id: taskId,
      title: 'Study: ${topic.title}',
      description: 'Topic from ${roadmapTitle ?? "Roadmap"}: ${topic.description}',
      status: TaskStatus.todo,
      priority: TaskPriority.high,
      dueDate: now,
      estimateMinutes: (topic.estimatedHours * 60).round().clamp(30, 180),
      roadmapTopicId: topic.id,
      isTopPriority: true,
      subtasks: topic.lessons
          .where((l) => !l.isCompleted)
          .map((l) => Subtask(
                id: _uuid.v4(),
                taskId: taskId,
                title: l.title,
                isCompleted: false,
                position: l.position,
              ))
          .toList(),
    );

    await db.transaction((txn) async {
      await txn.insert('tasks', task.toMap());
      for (final subtask in task.subtasks) {
        await txn.insert('subtasks', subtask.toMap());
      }
    });

    // Also mark topic as in_progress if currently available
    if (topic.status == TopicStatus.available) {
      await updateTopicStatus(topic.id, TopicStatus.inProgress);
    }

    return taskId;
  }

  Future<void> insertRoadmap(Roadmap roadmap) async {
    final db = await _db;
    final rId = roadmap.id.isEmpty ? _uuid.v4() : roadmap.id;
    await db.insert('roadmaps', roadmap.copyWith(id: rId).toMap());
  }

  Future<void> insertStage(RoadmapStage stage) async {
    final db = await _db;
    final sId = stage.id.isEmpty ? _uuid.v4() : stage.id;
    await db.insert('roadmap_stages', stage.copyWith(id: sId).toMap());
  }

  Future<void> insertTopic(Topic topic) async {
    final db = await _db;
    final tId = topic.id.isEmpty ? _uuid.v4() : topic.id;
    await db.insert('topics', topic.copyWith(id: tId).toMap());
  }

  Future<void> insertLesson(Lesson lesson) async {
    final db = await _db;
    final lId = lesson.id.isEmpty ? _uuid.v4() : lesson.id;
    await db.insert('lessons', lesson.copyWith(id: lId).toMap());
  }

  Future<void> insertResource(TopicResource resource) async {
    final db = await _db;
    final rId = resource.id.isEmpty ? _uuid.v4() : resource.id;
    await db.insert('topic_resources', resource.copyWith(id: rId).toMap());
  }
}
