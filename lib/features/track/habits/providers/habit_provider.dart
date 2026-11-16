import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

class SelectedHabitDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void jumpToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }
}

final selectedHabitDateProvider =
    NotifierProvider<SelectedHabitDateNotifier, DateTime>(SelectedHabitDateNotifier.new);

enum HabitViewMode {
  expanded,
  collapsed,
}

class HabitViewModeNotifier extends Notifier<HabitViewMode> {
  @override
  HabitViewMode build() => HabitViewMode.expanded;

  void toggle() {
    state = state == HabitViewMode.expanded ? HabitViewMode.collapsed : HabitViewMode.expanded;
  }

  void setMode(HabitViewMode mode) {
    state = mode;
  }
}

final habitViewModeProvider =
    NotifierProvider<HabitViewModeNotifier, HabitViewMode>(HabitViewModeNotifier.new);

class HabitTimeOfDayFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all'; // 'all', 'morning', 'afternoon', 'evening', 'night'

  void setFilter(String filter) => state = filter;
}

final selectedHabitTimeOfDayFilterProvider =
    NotifierProvider<HabitTimeOfDayFilterNotifier, String>(HabitTimeOfDayFilterNotifier.new);

class HabitCalendarExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setExpanded(bool expanded) => state = expanded;
}

final habitCalendarExpandedProvider =
    NotifierProvider<HabitCalendarExpandedNotifier, bool>(HabitCalendarExpandedNotifier.new);

/// List of habits with status calculated for the selected week
final habitsListProvider = FutureProvider<List<HabitWithStatus>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  final selectedDate = ref.watch(selectedHabitDateProvider);
  return await repo.getHabitsWithStatus(weekDate: selectedDate);
});

/// Filtered habits by time of day
final filteredHabitsListProvider = Provider<AsyncValue<List<HabitWithStatus>>>((ref) {
  final habitsAsync = ref.watch(habitsListProvider);
  final filter = ref.watch(selectedHabitTimeOfDayFilterProvider);

  return habitsAsync.whenData((habits) {
    if (filter == 'all') return habits;
    return habits.where((h) {
      if (h.habit.timeOfDay == 'all') return true;
      return h.habit.timeOfDay.toLowerCase() == filter.toLowerCase();
    }).toList();
  });
});

final todayHabitMetricsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getTodayHabitMetrics();
});

class HabitMonthQuery {
  final String habitId;
  final int year;
  final int month;

  const HabitMonthQuery({required this.habitId, required this.year, required this.month});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitMonthQuery &&
          runtimeType == other.runtimeType &&
          habitId == other.habitId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => habitId.hashCode ^ year.hashCode ^ month.hashCode;
}

final habitMonthLogsProvider =
    FutureProvider.family<HabitMonthResult, HabitMonthQuery>((ref, query) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getMonthLogs(query.habitId, query.year, query.month);
});

class HabitStatsQuery {
  final String habitId;
  final String period; // 'week', 'month', 'year'

  const HabitStatsQuery({required this.habitId, required this.period});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitStatsQuery &&
          runtimeType == other.runtimeType &&
          habitId == other.habitId &&
          period == other.period;

  @override
  int get hashCode => habitId.hashCode ^ period.hashCode;
}

final habitDetailedStatsProvider =
    FutureProvider.family<HabitDetailedStats, HabitStatsQuery>((ref, query) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getHabitDetailedStats(query.habitId, period: query.period);
});
