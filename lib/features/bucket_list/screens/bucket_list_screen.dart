import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/models/bucket_item.dart';
import '../providers/bucket_provider.dart';
import '../repositories/bucket_repository.dart';

class BucketListScreen extends ConsumerStatefulWidget {
  const BucketListScreen({super.key});

  @override
  ConsumerState<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends ConsumerState<BucketListScreen> {
  final _uuid = const Uuid();

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'movie':
        return Icons.movie_outlined;
      case 'game':
        return Icons.sports_esports_outlined;
      case 'book':
        return Icons.menu_book_rounded;
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'experience':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'movie':
        return const Color(0xFFEF4444);
      case 'game':
        return const Color(0xFF8B5CF6);
      case 'book':
        return const Color(0xFFF59E0B);
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'experience':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemsAsync = ref.watch(bucketListProvider);
    final currentCat = ref.watch(bucketCategoryFilterProvider);
    final currentStatus = ref.watch(bucketStatusFilterProvider);

    final categories = [
      {'key': 'all', 'label': 'All'},
      {'key': 'movie', 'label': 'Movies & Shows'},
      {'key': 'game', 'label': 'Games'},
      {'key': 'book', 'label': 'Books'},
      {'key': 'travel', 'label': 'Travel'},
      {'key': 'experience', 'label': 'Experiences'},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Bucket List & Media',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Item',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Status Filter Segment
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 4),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(value: 'wishlist', label: Text('Wishlist')),
                  ButtonSegment(value: 'in_progress', label: Text('In Progress')),
                  ButtonSegment(value: 'completed', label: Text('Done')),
                ],
                selected: {currentStatus},
                onSelectionChanged: (set) {
                  ref.read(bucketStatusFilterProvider.notifier).setStatus(set.first);
                },
              ),
            ),
          ),

          // 2. Category Filter Pills
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = currentCat == cat['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(cat['label']!, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(bucketCategoryFilterProvider.notifier).setCategory(cat['key']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 3. Bucket Items List
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Items Found',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track movies, video games, books, travel destinations & life goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showAddEditDialog(),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Bucket Item'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final catColor = _getCategoryColor(item.category);
                      final icon = _getCategoryIcon(item.category);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isCompleted
                                  ? const Color(0xFF10B981).withOpacity(0.4)
                                  : (isDark ? const Color(0xFF2C2C34) : const Color(0xFFECECF0)),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: catColor, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.categoryDisplay.toUpperCase(),
                                      style: TextStyle(
                                        color: catColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Status Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.status == 'completed'
                                          ? const Color(0xFF10B981).withOpacity(0.15)
                                          : (item.status == 'in_progress'
                                              ? const Color(0xFF3B82F6).withOpacity(0.15)
                                              : (isDark ? const Color(0xFF2A2A30) : const Color(0xFFECECF0))),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.status == 'completed'
                                          ? 'COMPLETED'
                                          : (item.status == 'in_progress' ? 'IN PROGRESS' : 'WISHLIST'),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: item.status == 'completed'
                                            ? const Color(0xFF10B981)
                                            : (item.status == 'in_progress'
                                                ? const Color(0xFF3B82F6)
                                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                                    onSelected: (val) async {
                                      if (val == 'delete') {
                                        await ref.read(bucketRepositoryProvider).deleteBucketItem(item.id);
                                        ref.invalidate(bucketListProvider);
                                      } else if (val == 'edit') {
                                        _showAddEditDialog(item: item);
                                      } else {
                                        await ref.read(bucketRepositoryProvider).setStatus(item.id, val);
                                        ref.invalidate(bucketListProvider);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      if (item.status != 'in_progress')
                                        const PopupMenuItem(value: 'in_progress', child: Text('Mark In Progress')),
                                      if (item.status != 'completed')
                                        const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                                      if (item.status != 'wishlist')
                                        const PopupMenuItem(value: 'wishlist', child: Text('Move to Wishlist')),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: item.isCompleted ? const Color(0xFF10B981) : Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final next = item.isCompleted ? 'wishlist' : 'completed';
                                      await ref.read(bucketRepositoryProvider).setStatus(item.id, next);
                                      ref.invalidate(bucketListProvider);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                        color: item.isCompleted
                                            ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Rating & Target Date
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Row(
                                  children: [
                                    // 5-Star Rating
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        final curRating = item.rating ?? 0.0;
                                        final isLit = starIdx < curRating;
                                        return InkWell(
                                          onTap: () async {
                                            final newRating = (starIdx + 1).toDouble();
                                            await ref.read(bucketRepositoryProvider).setRating(item.id, newRating);
                                            ref.invalidate(bucketListProvider);
                                          },
                                          child: Icon(
                                            isLit ? Icons.star_rounded : Icons.star_outline_rounded,
                                            size: 16,
                                            color: isLit ? const Color(0xFFF59E0B) : Colors.grey.shade600,
                                          ),
                                        );
                                      }),
                                    ),
                                    const Spacer(),
                                    if (item.targetDate != null && item.targetDate!.isNotEmpty) ...[
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.targetDate!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error loading bucket list: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddEditDialog({BucketItem? item}) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final notesCtrl = TextEditingController(text: item?.notes ?? '');
    String category = item?.category ?? 'movie';
    String status = item?.status ?? 'wishlist';
    String? targetDate = item?.targetDate;

    final categories = [
      {'key': 'movie', 'label': 'Movie / TV Show'},
      {'key': 'game', 'label': 'Video Game'},
      {'key': 'book', 'label': 'Book'},
      {'key': 'travel', 'label': 'Travel Destination'},
      {'key': 'experience', 'label': 'Life Experience'},
      {'key': 'other', 'label': 'Other'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add to Bucket List' : 'Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: item == null,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Interstellar, Elden Ring, Visit Iceland',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) {
                    return DropdownMenuItem(value: c['key'], child: Text(c['label']!));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'wishlist', child: Text('Wishlist (To Do / To Watch)')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress (Currently Watching/Playing)')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed (Done)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded, size: 20),
                  title: Text(
                    targetDate == null ? 'Target Date (Optional)' : 'Target: $targetDate',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: targetDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () => setDialogState(() => targetDate = null),
                        )
                      : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        targetDate = DateFormat('yyyy-MM-dd').format(picked);
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Review / Impressions',
                    hintText: 'Thoughts, expectations, or rating summary',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final newItem = BucketItem(
                  id: item?.id ?? _uuid.v4(),
                  title: title,
                  category: category,
                  status: status,
                  rating: item?.rating,
                  notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  targetDate: targetDate,
                  completedAt: status == 'completed' ? (item?.completedAt ?? DateTime.now().toIso8601String()) : null,
                  createdAt: item?.createdAt ?? DateTime.now(),
                );

                await ref.read(bucketRepositoryProvider).saveBucketItem(newItem);
                ref.invalidate(bucketListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(item == null ? 'Add Item' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
