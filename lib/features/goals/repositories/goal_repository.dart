import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/goal_project.dart';

class GoalRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  GoalRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<Goal>> getGoals() async {
    final db = await _db;
    final goalRows = await db.query('goals', orderBy: 'created_at DESC');
    final List<Goal> goals = [];

    for (final gRow in goalRows) {
      final gId = gRow['id'] as String;
      final mRows = await db.query(
        'milestones',
        where: 'goal_id = ?',
        whereArgs: [gId],
        orderBy: 'due_date ASC',
      );
      final milestones = mRows.map((m) => Milestone.fromMap(m)).toList();
      goals.add(Goal.fromMap(gRow, milestones: milestones));
    }
    return goals;
  }

  Future<List<Project>> getProjects() async {
    final db = await _db;
    final rows = await db.query('projects', orderBy: 'created_at DESC');
    final List<Project> projects = [];

    for (final r in rows) {
      final pId = r['id'] as String;
      final fRows = await db.query(
        'project_features',
        where: 'project_id = ?',
        whereArgs: [pId],
        orderBy: 'position ASC, created_at ASC',
      );
      final features = fRows.map((f) => ProjectFeature.fromMap(f)).toList();
      projects.add(Project.fromMap(r, features: features));
    }
    return projects;
  }

  Future<void> insertGoal(Goal goal) async {
    final db = await _db;
    final gId = goal.id.isEmpty ? _uuid.v4() : goal.id;
    await db.transaction((txn) async {
      await txn.insert('goals', goal.copyWith(id: gId).toMap());
      for (final m in goal.milestones) {
        final mId = m.id.isEmpty ? _uuid.v4() : m.id;
        await txn.insert('milestones', m.copyWith(id: mId, goalId: gId).toMap());
      }
    });
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await _db;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(String goalId) async {
    final db = await _db;
    await db.delete('goals', where: 'id = ?', whereArgs: [goalId]);
  }

  Future<void> insertMilestone(Milestone milestone) async {
    final db = await _db;
    final mId = milestone.id.isEmpty ? _uuid.v4() : milestone.id;
    await db.insert('milestones', milestone.copyWith(id: mId).toMap());
  }

  Future<void> toggleMilestone(String milestoneId, bool isCompleted) async {
    final db = await _db;
    await db.update(
      'milestones',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [milestoneId],
    );
  }

  Future<void> deleteMilestone(String milestoneId) async {
    final db = await _db;
    await db.delete('milestones', where: 'id = ?', whereArgs: [milestoneId]);
  }

  // --- Project Management & Features ---

  Future<void> insertProject(Project project) async {
    final db = await _db;
    final pId = project.id.isEmpty ? _uuid.v4() : project.id;
    await db.insert('projects', project.copyWith(id: pId).toMap());
  }

  Future<void> updateProject(Project project) async {
    final db = await _db;
    await db.update('projects', project.toMap(), where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> deleteProject(String projectId) async {
    final db = await _db;
    await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);
  }

  Future<void> insertProjectFeature(ProjectFeature feature) async {
    final db = await _db;
    final fId = feature.id.isEmpty ? _uuid.v4() : feature.id;
    await db.insert('project_features', feature.copyWith(id: fId).toMap());
  }

  Future<void> updateProjectFeatureStatus(String featureId, String status) async {
    final db = await _db;
    await db.update(
      'project_features',
      {'status': status},
      where: 'id = ?',
      whereArgs: [featureId],
    );
  }

  Future<void> deleteProjectFeature(String featureId) async {
    final db = await _db;
    await db.delete('project_features', where: 'id = ?', whereArgs: [featureId]);
  }
}
