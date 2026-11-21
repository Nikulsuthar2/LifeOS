import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/bucket_item.dart';

final bucketRepositoryProvider = Provider<BucketRepository>((ref) {
  return BucketRepository();
});

class BucketRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<BucketItem>> getBucketItems({String? category, String? status}) async {
    final db = await _db;
    String whereClause = '1=1';
    final List<dynamic> whereArgs = [];

    if (category != null && category != 'all') {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }
    if (status != null && status != 'all') {
      whereClause += ' AND status = ?';
      whereArgs.add(status);
    }

    final rows = await db.query(
      'bucket_list',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => BucketItem.fromMap(r)).toList();
  }

  Future<void> saveBucketItem(BucketItem item) async {
    final db = await _db;
    await db.insert(
      'bucket_list',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBucketItem(String id) async {
    final db = await _db;
    await db.delete('bucket_list', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setStatus(String id, String status) async {
    final db = await _db;
    final completedAt = status == 'completed' ? DateTime.now().toIso8601String() : null;
    await db.update(
      'bucket_list',
      {
        'status': status,
        'completed_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setRating(String id, double rating) async {
    final db = await _db;
    await db.update(
      'bucket_list',
      {'rating': rating},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
