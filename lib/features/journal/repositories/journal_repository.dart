import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/journal.dart';

class JournalRepository {
  final AppDatabase _dbProvider;
  static const _uuid = Uuid();

  JournalRepository({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db => _dbProvider.database;

  Future<List<JournalEntry>> getEntries() async {
    final db = await _db;
    final rows = await db.query('journal_entries', orderBy: 'date_str DESC');
    return rows.map((r) => JournalEntry.fromMap(r)).toList();
  }

  Future<JournalEntry?> getEntryForDate(String dateStr) async {
    final db = await _db;
    final rows = await db.query('journal_entries', where: 'date_str = ?', whereArgs: [dateStr]);
    if (rows.isEmpty) return null;
    return JournalEntry.fromMap(rows.first);
  }

  Future<void> saveEntry(JournalEntry entry) async {
    final db = await _db;
    final existing = await getEntryForDate(entry.dateStr);

    if (existing == null) {
      final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
      await db.insert('journal_entries', entry.copyWith(id: id).toMap());
    } else {
      await db.update(
        'journal_entries',
        entry.toMap(),
        where: 'date_str = ?',
        whereArgs: [entry.dateStr],
      );
    }
  }
}

