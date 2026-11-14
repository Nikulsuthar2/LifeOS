import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
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
        onOpen: (db) async {
          await _ensureSchemaUpdates(db);
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
      onOpen: (db) async {
        await _ensureSchemaUpdates(db);
      },
    );
  }

  Future<void> _ensureSchemaUpdates(Database db) async {
    // Add columns if they do not exist
    try {
      await db.execute('ALTER TABLE tasks ADD COLUMN is_all_day INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE tasks ADD COLUMN end_date TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE tasks ADD COLUMN recurrence_end_date TEXT');
    } catch (_) {}
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_templates (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          priority TEXT DEFAULT 'medium',
          estimate_minutes INTEGER DEFAULT 30,
          is_all_day INTEGER DEFAULT 0,
          category TEXT DEFAULT 'General',
          subtasks_json TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}
    await _seedDefaultTemplatesIfEmpty(db);
  }

  Future<void> _seedDefaultTemplatesIfEmpty(Database db) async {
    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM task_templates'),
      ) ?? 0;
      if (count == 0) {
        final now = DateTime.now().toIso8601String();
        final defaultTemplates = [
          {
            'id': 'template-deep-work',
            'title': 'Deep Work Session',
            'description': 'Uninterrupted 90-minute block for high-leverage focus.',
            'priority': 'high',
            'estimate_minutes': 90,
            'is_all_day': 0,
            'category': 'Focus',
            'subtasks_json': '["Close Slack and email tabs","Define 1 specific outcome","90-min focused timer","Quick log of progress"]',
            'created_at': now,
          },
          {
            'id': 'template-daily-planning',
            'title': 'Daily Morning Planning',
            'description': 'Review calendar, choose 3 MITs, clear inbox.',
            'priority': 'medium',
            'estimate_minutes': 15,
            'is_all_day': 0,
            'category': 'Planning',
            'subtasks_json': '["Review scheduled meetings","Select Top 3 Priorities","Scan task backlog"]',
            'created_at': now,
          },
          {
            'id': 'template-weekly-review',
            'title': 'Weekly Life & Project Review',
            'description': 'Reflect on accomplishments, clear inboxes, plan next week.',
            'priority': 'high',
            'estimate_minutes': 45,
            'is_all_day': 0,
            'category': 'Review',
            'subtasks_json': '["Review last week wins & metrics","Update project roadmaps","Plan priorities for next week","Clean workspace & digital files"]',
            'created_at': now,
          },
          {
            'id': 'template-code-review',
            'title': 'Code Architecture & QA Review',
            'description': 'Inspect pull request, verify unit tests, check edge cases.',
            'priority': 'medium',
            'estimate_minutes': 30,
            'is_all_day': 0,
            'category': 'Engineering',
            'subtasks_json': '["Read PR description and changes","Run unit & integration tests","Check performance & edge cases","Submit constructive feedback"]',
            'created_at': now,
          },
        ];
        for (final t in defaultTemplates) {
          await db.insert('task_templates', t);
        }
      }
    } catch (_) {}
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
  Future<void> resetToSampleData() => resetToSeedData();

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
