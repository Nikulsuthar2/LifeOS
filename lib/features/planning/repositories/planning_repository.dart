import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/daily_plan.dart';

class PlanningRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  PlanningRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<ScheduleBlock>> getScheduleBlocks(String dateStr) async {
    final db = await _db;
    final rows = await db.query(
      'schedule_blocks',
      where: 'date_str = ?',
      whereArgs: [dateStr],
      orderBy: 'start_time ASC',
    );
    return rows.map((r) => ScheduleBlock.fromMap(r)).toList();
  }

  Future<void> insertScheduleBlock(ScheduleBlock block) async {
    final db = await _db;
    final bId = block.id.isEmpty ? _uuid.v4() : block.id;
    await db.insert('schedule_blocks', block.copyWith(id: bId).toMap());
  }

  Future<void> toggleScheduleBlock(String id, bool isCompleted) async {
    final db = await _db;
    await db.update(
      'schedule_blocks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteScheduleBlock(String id) async {
    final db = await _db;
    await db.delete('schedule_blocks', where: 'id = ?', whereArgs: [id]);
  }
}

