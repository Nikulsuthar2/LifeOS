import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/daily_plan.dart';
import '../repositories/planning_repository.dart';

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepository();
});

class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void setDate(String dateStr) {
    state = dateStr;
  }
}

final selectedDateStrProvider = NotifierProvider<SelectedDateNotifier, String>(SelectedDateNotifier.new);

final scheduleBlocksProvider = FutureProvider<List<ScheduleBlock>>((ref) async {
  final repo = ref.watch(planningRepositoryProvider);
  final dateStr = ref.watch(selectedDateStrProvider);
  return await repo.getScheduleBlocks(dateStr);
});
