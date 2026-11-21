import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/journal.dart';
import '../repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

class JournalMoodFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  set state(String val) => super.state = val;
}

final journalMoodFilterProvider = NotifierProvider<JournalMoodFilterNotifier, String>(JournalMoodFilterNotifier.new);

class JournalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set state(String val) => super.state = val;
}

final journalSearchQueryProvider = NotifierProvider<JournalSearchQueryNotifier, String>(JournalSearchQueryNotifier.new);

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final mood = ref.watch(journalMoodFilterProvider);
  final query = ref.watch(journalSearchQueryProvider);

  return await repo.getEntriesFiltered(
    mood: mood == 'all' ? null : mood,
    query: query.isEmpty ? null : query,
  );
});

final todayJournalEntryProvider = FutureProvider<JournalEntry?>((ref) async {
  final repo = ref.watch(journalRepositoryProvider);
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return await repo.getEntryForDate(todayStr);
});
