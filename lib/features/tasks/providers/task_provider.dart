import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

enum TaskViewMode { list, calendar }

class TaskViewModeNotifier extends Notifier<TaskViewMode> {
  @override
  TaskViewMode build() => TaskViewMode.list;

  void setMode(TaskViewMode mode) => state = mode;
  void toggle() => state = state == TaskViewMode.list ? TaskViewMode.calendar : TaskViewMode.list;
}

final taskViewModeProvider = NotifierProvider<TaskViewModeNotifier, TaskViewMode>(TaskViewModeNotifier.new);

enum CalendarViewType { day, week, month, schedule }

class CalendarViewTypeNotifier extends Notifier<CalendarViewType> {
  @override
  CalendarViewType build() => CalendarViewType.day;

  void setType(CalendarViewType type) => state = type;
}

final calendarViewTypeProvider = NotifierProvider<CalendarViewTypeNotifier, CalendarViewType>(CalendarViewTypeNotifier.new);

class TaskFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all'; // 'all', 'pending', 'completed', 'inbox'

  void setFilter(String filter) {
    state = filter;
  }
}

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, String>(TaskFilterNotifier.new);

class SelectedTaskDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void jumpToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedTaskDateProvider = NotifierProvider<SelectedTaskDateNotifier, DateTime>(
  SelectedTaskDateNotifier.new,
);

final tasksListProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);
  final selectedDate = ref.watch(selectedTaskDateProvider);

  if (filter == 'inbox') {
    return await repo.getTasks(status: 'inbox');
  }

  return await repo.getTasksForDate(selectedDate, filter: filter);
});

final calendarTasksProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final selectedDate = ref.watch(selectedTaskDateProvider);
  final viewType = ref.watch(calendarViewTypeProvider);

  DateTime start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  DateTime end = start;

  switch (viewType) {
    case CalendarViewType.day:
      start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      end = start;
      break;
    case CalendarViewType.week:
      start = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      end = start.add(const Duration(days: 6));
      break;
    case CalendarViewType.month:
      start = DateTime(selectedDate.year, selectedDate.month, 1).subtract(const Duration(days: 7));
      end = DateTime(selectedDate.year, selectedDate.month + 1, 7);
      break;
    case CalendarViewType.schedule:
      start = selectedDate.subtract(const Duration(days: 3));
      end = selectedDate.add(const Duration(days: 30));
      break;
  }

  return await repo.getTasksForDateRange(start, end);
});

final taskTemplatesProvider = FutureProvider<List<TaskTemplate>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTemplates();
});

final weekTaskDatesProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  final selectedDate = ref.watch(selectedTaskDateProvider);

  // Determine start of week (Monday)
  final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return await repo.getTaskDatesForWeek(startOfWeek, endOfWeek);
});

final topPrioritiesProvider = FutureProvider<List<TaskItem>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTopPrioritiesForToday();
});

final todayTaskMetricsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return await repo.getTodayTaskMetrics();
});

