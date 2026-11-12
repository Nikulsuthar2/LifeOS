import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/journal.dart';
import '../repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  return await repo.getEntries();
});

final todayJournalEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return await repo.getEntryForDate(todayStr);
});

