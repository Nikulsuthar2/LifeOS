import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/skill.dart';

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return SkillRepository();
});

class SkillRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<PolymathSkill>> getSkills({String? status, String? domain}) async {
    final db = await _db;
    String whereClause = '1=1';
    final List<dynamic> whereArgs = [];

    if (status != null && status != 'all') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }
    if (domain != null && domain != 'All') {
      whereClause += ' AND domain = ?';
      whereArgs.add(domain);
    }

    final rows = await db.query(
      'polymath_skills',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'level DESC, xp DESC',
    );
    return rows.map((r) => PolymathSkill.fromMap(r)).toList();
  }

  Future<List<String>> getUniqueDomains() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT DISTINCT domain FROM polymath_skills ORDER BY domain ASC');
    return rows.map((r) => r['domain'] as String).where((d) => d.isNotEmpty).toList();
  }

  Future<void> saveSkill(PolymathSkill skill) async {
    final db = await _db;
    await db.insert(
      'polymath_skills',
      skill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSkill(String id) async {
    final db = await _db;
    await db.delete('polymath_skills', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setSkillStatus(String id, String status) async {
    final db = await _db;
    await db.update('polymath_skills', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<PolymathSkill?> addPracticeXp(String id, int xp) async {
    final db = await _db;
    final rows = await db.query('polymath_skills', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final current = PolymathSkill.fromMap(rows.first);
    var newXp = current.currentXp + xp;
    var newLevel = current.level;
    var newTarget = current.targetXp;
    var newStatus = current.status;

    while (newXp >= newTarget && newLevel < 5) {
      newXp -= newTarget;
      newLevel += 1;
      newTarget = (newTarget * 1.5).round();
      if (newLevel == 5) {
        newStatus = 'mastered';
      }
    }

    final updated = current.copyWith(
      currentXp: newXp,
      level: newLevel,
      targetXp: newTarget,
      status: newStatus,
    );

    await db.update('polymath_skills', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    return updated;
  }
}
