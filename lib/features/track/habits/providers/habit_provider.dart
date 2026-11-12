import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

final habitsListProvider = FutureProvider<List<HabitWithStatus>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getHabitsWithStatus();
});

final todayHabitMetricsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getTodayHabitMetrics();
});

