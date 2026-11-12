import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'initial_seed.dart';
import 'schema.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  static void initPlatform() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<void> initForTest() async {
    initPlatform();
    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await InitialDatabaseSeed.seed(db);
      },
    );
  }

  Future<Database> _initDatabase({String dbName = 'life_os.db', bool inMemory = false}) async {
    initPlatform();

    if (inMemory) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await _createTables(db);
          await InitialDatabaseSeed.seed(db);
        },
      );
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationDocumentsDirectory();
      path = p.join(docDir.path, 'LifeOS', dbName);
      final dir = Directory(p.dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, dbName);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await InitialDatabaseSeed.seed(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    for (final sql in DatabaseSchema.createTables) {
      await db.execute(sql);
    }
    for (final sql in DatabaseSchema.createIndices) {
      await db.execute(sql);
    }
  }

  // Backup & JSON Export
  Future<String> exportToJson() async {
    final db = await database;
    final Map<String, dynamic> data = {};

    final tables = [
      'tasks',
      'subtasks',
      'habits',
      'habit_logs',
      'focus_sessions',
      'roadmaps',
      'roadmap_stages',
      'topics',
      'lessons',
      'topic_resources',
      'goals',
      'milestones',
      'projects',
      'schedule_blocks',
      'journal_entries',
    ];

    for (final table in tables) {
      data[table] = await db.query(table);
    }

    data['exported_at'] = DateTime.now().toIso8601String();
    data['version'] = '1.0.0';
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // Restore from JSON
  Future<void> restoreFromJson(String jsonString) async {
    final db = await database;
    final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;

    await db.transaction((txn) async {
      final tables = [
        'tasks',
        'subtasks',
        'habits',
        'habit_logs',
        'focus_sessions',
        'roadmaps',
        'roadmap_stages',
        'topics',
        'lessons',
        'topic_resources',
        'goals',
        'milestones',
        'projects',
        'schedule_blocks',
        'journal_entries',
      ];

      for (final table in tables.reversed) {
        await txn.delete(table);
      }

      for (final table in tables) {
        if (data.containsKey(table) && data[table] is List) {
          final rows = (data[table] as List).cast<Map<String, dynamic>>();
          for (final row in rows) {
            await txn.insert(table, row);
          }
        }
      }
    });
  }

  // Reset to sample data
  Future<void> resetToSeedData() async {
    final db = await database;
    await db.transaction((txn) async {
      final tables = [
        'subtasks',
        'tasks',
        'habit_logs',
        'habits',
        'focus_sessions',
        'topic_resources',
        'lessons',
        'topics',
        'roadmap_stages',
        'roadmaps',
        'milestones',
        'projects',
        'goals',
        'schedule_blocks',
        'journal_entries',
      ];
      for (final table in tables) {
        await txn.delete(table);
      }
      await InitialDatabaseSeed.seed(txn as Database);
    });
  }
}
