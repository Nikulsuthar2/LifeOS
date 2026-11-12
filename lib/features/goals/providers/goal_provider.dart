import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/goal_project.dart';
import '../repositories/goal_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final goalsListProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return await repo.getGoals();
});

final projectsListProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return await repo.getProjects();
});

