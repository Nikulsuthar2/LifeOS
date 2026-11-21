import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/routine.dart';
import '../repositories/routine_repository.dart';

final routineBlocksProvider = FutureProvider<List<RoutineBlock>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  return await repo.getRoutineBlocks();
});

final currentActiveBlockProvider = Provider<RoutineBlock?>((ref) {
  final blocksAsync = ref.watch(routineBlocksProvider);
  return blocksAsync.when(
    data: (blocks) {
      try {
        return blocks.firstWhere((b) => b.isNow());
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, _) => null,
  );
});
