import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/roadmap.dart';
import '../repositories/roadmap_repository.dart';

final roadmapRepositoryProvider = Provider<RoadmapRepository>((ref) {
  return RoadmapRepository();
});

final roadmapsListProvider = FutureProvider<List<Roadmap>>((ref) async {
  final repo = ref.watch(roadmapRepositoryProvider);
  return await repo.getRoadmaps();
});

final activeRoadmapSpotlightProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(roadmapRepositoryProvider);
  return await repo.getActiveRoadmapSpotlight();
});

final selectedRoadmapProvider = FutureProvider.family<Roadmap?, String>((ref, id) async {
  final repo = ref.watch(roadmapRepositoryProvider);
  return await repo.getRoadmapById(id);
});

