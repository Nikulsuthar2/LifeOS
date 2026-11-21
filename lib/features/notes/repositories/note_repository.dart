import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/note.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

class NoteRepository {
  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<List<NoteItem>> getNotes({String? folder, String? tag, String? query}) async {
    final db = await _db;
    String sql = 'SELECT * FROM notes';
    List<dynamic> args = [];
    List<String> conditions = [];

    if (folder != null && folder != 'All') {
      conditions.add('folder = ?');
      args.add(folder);
    }

    if (tag != null && tag.isNotEmpty) {
      conditions.add('tags LIKE ?');
      args.add('%$tag%');
    }

    if (query != null && query.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR content LIKE ?)');
      final term = '%${query.trim()}%';
      args.add(term);
      args.add(term);
    }

    if (conditions.isNotEmpty) {
      sql += ' WHERE ${conditions.join(' AND ')}';
    }

    sql += ' ORDER BY is_pinned DESC, updated_at DESC';

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => NoteItem.fromMap(r)).toList();
  }

  Future<void> insertNote(NoteItem note) async {
    final db = await _db;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateNote(NoteItem note) async {
    final db = await _db;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(String id) async {
    final db = await _db;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> togglePin(String id, bool isPinned) async {
    final db = await _db;
    await db.update(
      'notes',
      {'is_pinned': isPinned ? 1 : 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getFolders() async {
    final db = await _db;
    final rows = await db.rawQuery('SELECT DISTINCT folder FROM notes ORDER BY folder ASC');
    final folders = rows.map((r) => (r['folder'] as String?) ?? 'General').toSet().toList();
    if (!folders.contains('General')) folders.insert(0, 'General');
    return folders;
  }
}
