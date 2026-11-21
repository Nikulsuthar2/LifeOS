import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gamification.dart';
import '../repositories/gamification_repository.dart';

final gamificationProfileProvider = FutureProvider<GamificationProfile>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getProfile();
});

final gamificationBadgesProvider = FutureProvider<List<GamificationBadge>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getBadges();
});

final gamificationXpLogsProvider = FutureProvider<List<GamificationXpLog>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getXpLogs();
});

final dailyLifeScoreProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getDailyLifeScore(DateTime.now());
});

final activityHeatmapProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getActivityHeatmap(days: 84); // 12 weeks
});
