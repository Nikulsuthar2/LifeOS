import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/routine.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository();
});

class RoutineRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<RoutineBlock>> getRoutineBlocks() async {
    final db = await _db;
    final rows = await db.query(
      'routines_24h',
      where: 'is_active = 1',
      orderBy: 'start_time ASC',
    );
    return rows.map((r) => RoutineBlock.fromMap(r)).toList();
  }

  Future<List<RoutineBlock>> getAllRoutineBlocks() async {
    final db = await _db;
    final rows = await db.query(
      'routines_24h',
      orderBy: 'start_time ASC',
    );
    return rows.map((r) => RoutineBlock.fromMap(r)).toList();
  }

  Future<void> saveRoutineBlock(RoutineBlock block) async {
    final db = await _db;
    await db.insert(
      'routines_24h',
      block.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoutineBlock(String id) async {
    final db = await _db;
    await db.delete(
      'routines_24h',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleBlockActive(String id, bool isActive) async {
    final db = await _db;
    await db.update(
      'routines_24h',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
