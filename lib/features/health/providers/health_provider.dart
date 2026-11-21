import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/health.dart';
import '../repositories/health_repository.dart';

class HealthDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  set state(DateTime val) => super.state = val;
  void setDate(DateTime val) => super.state = val;
}

final healthDateProvider = NotifierProvider<HealthDateNotifier, DateTime>(HealthDateNotifier.new);

final latestVitalsProvider = FutureProvider<HealthVitals?>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return await repo.getLatestVitals();
});

final todayWaterLogProvider = FutureProvider<HealthWaterLog>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  final date = ref.watch(healthDateProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  return await repo.getWaterLog(dateStr);
});

final sleepLogsProvider = FutureProvider<List<HealthSleepLog>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return await repo.getSleepLogs();
});

final healthProductsProvider = FutureProvider<List<HealthProduct>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return await repo.getProducts();
});

final takenProductIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  final date = ref.watch(healthDateProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  return await repo.getTakenProductIdsForDate(dateStr);
});

final workoutsListProvider = FutureProvider<List<HealthWorkout>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return await repo.getWorkouts();
});

final mealsForDateProvider = FutureProvider<List<HealthMeal>>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  final date = ref.watch(healthDateProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  return await repo.getMealsForDate(dateStr);
});
