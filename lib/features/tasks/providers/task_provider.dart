import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

class TaskFilterNotifier extends Notifier<String> {
  @override
  String build() => 'today';

  void setFilter(String filter) {
    state = filter;
  }
}

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, String>(TaskFilterNotifier.new);

final tasksListProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);
  return await repo.getTasks(status: filter);
});

final topPrioritiesProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTopPrioritiesForToday();
});

final todayTaskMetricsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTodayTaskMetrics();
});
