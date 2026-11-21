import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/health.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository();
});

class HealthRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  // --- Vitals ---
  Future<HealthVitals?> getLatestVitals() async {
    final db = await _db;
    final rows = await db.query('health_vitals', orderBy: 'date_str DESC, created_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    return HealthVitals.fromMap(rows.first);
  }

  Future<void> saveVitals(HealthVitals vitals) async {
    final db = await _db;
    await db.insert('health_vitals', vitals.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Water ---
  Future<HealthWaterLog> getWaterLog(String dateStr) async {
    final db = await _db;
    final rows = await db.query('health_water_logs', where: 'date_str = ?', whereArgs: [dateStr]);
    if (rows.isEmpty) {
      return HealthWaterLog(id: 'water-$dateStr', dateStr: dateStr, glassesDrank: 0);
    }
    return HealthWaterLog.fromMap(rows.first);
  }

  Future<void> updateWaterGlasses(String dateStr, int glasses) async {
    final db = await _db;
    final log = HealthWaterLog(
      id: 'water-$dateStr',
      dateStr: dateStr,
      glassesDrank: glasses.clamp(0, 30),
      updatedAt: DateTime.now(),
    );
    await db.insert('health_water_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Sleep ---
  Future<List<HealthSleepLog>> getSleepLogs() async {
    final db = await _db;
    final rows = await db.query('health_sleep_logs', orderBy: 'date_str DESC', limit: 14);
    return rows.map((r) => HealthSleepLog.fromMap(r)).toList();
  }

  Future<void> saveSleepLog(HealthSleepLog sleep) async {
    final db = await _db;
    await db.insert('health_sleep_logs', sleep.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Products & Medicine ---
  Future<List<HealthProduct>> getProducts({String? category}) async {
    final db = await _db;
    String sql = 'SELECT * FROM health_products WHERE is_active = 1';
    List<dynamic> args = [];
    if (category != null && category != 'All') {
      sql += ' AND category = ?';
      args.add(category.toLowerCase());
    }
    sql += ' ORDER BY category ASC, name ASC';
    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => HealthProduct.fromMap(r)).toList();
  }

  Future<void> saveProduct(HealthProduct product) async {
    final db = await _db;
    await db.insert('health_products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(String id) async {
    final db = await _db;
    await db.delete('health_products', where: 'id = ?', whereArgs: [id]);
  }

  Future<Set<String>> getTakenProductIdsForDate(String dateStr) async {
    final db = await _db;
    final rows = await db.query('health_product_logs', where: 'date_str = ?', whereArgs: [dateStr]);
    return rows.map((r) => r['product_id'] as String).toSet();
  }

  Future<void> toggleProductTaken(String productId, String dateStr, bool taken) async {
    final db = await _db;
    if (taken) {
      await db.insert('health_product_logs', {
        'id': '$productId-$dateStr',
        'product_id': productId,
        'date_str': dateStr,
        'is_taken': 1,
        'taken_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('health_product_logs', where: 'product_id = ? AND date_str = ?', whereArgs: [productId, dateStr]);
    }
  }

  // --- Workouts ---
  Future<List<HealthWorkout>> getWorkouts() async {
    final db = await _db;
    final rows = await db.query('health_workouts', orderBy: 'date_str DESC, created_at DESC', limit: 20);
    return rows.map((r) => HealthWorkout.fromMap(r)).toList();
  }

  Future<void> saveWorkout(HealthWorkout workout) async {
    final db = await _db;
    await db.insert('health_workouts', workout.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteWorkout(String id) async {
    final db = await _db;
    await db.delete('health_workouts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Meals ---
  Future<List<HealthMeal>> getMealsForDate(String dateStr) async {
    final db = await _db;
    final rows = await db.query('health_meals', where: 'date_str = ?', whereArgs: [dateStr], orderBy: 'created_at ASC');
    return rows.map((r) => HealthMeal.fromMap(r)).toList();
  }

  Future<void> saveMeal(HealthMeal meal) async {
    final db = await _db;
    await db.insert('health_meals', meal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMeal(String id) async {
    final db = await _db;
    await db.delete('health_meals', where: 'id = ?', whereArgs: [id]);
  }
}
