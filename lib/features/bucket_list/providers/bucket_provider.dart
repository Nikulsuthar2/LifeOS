import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bucket_item.dart';
import '../repositories/bucket_repository.dart';

class BucketCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setCategory(String val) => state = val;
}

final bucketCategoryFilterProvider = NotifierProvider<BucketCategoryFilterNotifier, String>(
  BucketCategoryFilterNotifier.new,
);

class BucketStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setStatus(String val) => state = val;
}

final bucketStatusFilterProvider = NotifierProvider<BucketStatusFilterNotifier, String>(
  BucketStatusFilterNotifier.new,
);

final bucketListProvider = FutureProvider<List<BucketItem>>((ref) async {
  final repo = ref.watch(bucketRepositoryProvider);
  final cat = ref.watch(bucketCategoryFilterProvider);
  final status = ref.watch(bucketStatusFilterProvider);

  return await repo.getBucketItems(category: cat, status: status);
});
