import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/note.dart';
import '../repositories/note_repository.dart';

class NoteFolderNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  set state(String val) => super.state = val;
}

final selectedNoteFolderProvider = NotifierProvider<NoteFolderNotifier, String>(NoteFolderNotifier.new);

class NoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set state(String val) => super.state = val;
}

final noteSearchQueryProvider = NotifierProvider<NoteSearchQueryNotifier, String>(NoteSearchQueryNotifier.new);

final notesListProvider = FutureProvider<List<NoteItem>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  final folder = ref.watch(selectedNoteFolderProvider);
  final query = ref.watch(noteSearchQueryProvider);

  return await repo.getNotes(
    folder: folder == 'All' ? null : folder,
    query: query.isEmpty ? null : query,
  );
});

final noteFoldersProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return await repo.getFolders();
});
