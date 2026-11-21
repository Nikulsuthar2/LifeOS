import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/models/routine.dart';
import '../providers/routine_provider.dart';
import '../repositories/routine_repository.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final routineAsync = ref.watch(routineBlocksProvider);
    final activeBlock = ref.watch(currentActiveBlockProvider);
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '24-Hour Routine',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Apply Polymath Preset',
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            onPressed: _applyPolymathPreset,
          ),
          IconButton(
            tooltip: 'Add Time Block',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditBlockSheet(),
          ),
        ],
      ),
      body: routineAsync.when(
        data: (blocks) {
          return CustomScrollView(
            slivers: [
              // 1. Active Now Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: activeBlock != null
                          ? activeBlock.color.withOpacity(0.12)
                          : (isDark ? const Color(0xFF1E1E24) : const Color(0xFFF1F1F5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: activeBlock != null
                            ? activeBlock.color.withOpacity(0.4)
                            : (isDark ? const Color(0xFF2C2C34) : const Color(0xFFE5E5EB)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: activeBlock != null ? activeBlock.color : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activeBlock != null ? Icons.play_arrow_rounded : Icons.schedule_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: activeBlock != null ? activeBlock.color : Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      activeBlock != null ? 'ACTIVE NOW • $timeStr' : 'FREE TIME • $timeStr',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (activeBlock != null)
                                    Text(
                                      activeBlock.formattedDuration,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: activeBlock.color,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                activeBlock?.title ?? 'No scheduled block currently',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              if (activeBlock != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${activeBlock.startTime} – ${activeBlock.endTime} • ${activeBlock.category}',
                                  style: TextStyle(
                                    fontSize: 12,
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
                ),
              ),

              // 2. Timeline Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Full 24-Hour Cycle',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${blocks.length} blocks scheduled',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Blocks List with Timeline Axis
              if (blocks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Routine Blocks Configured',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create a custom block or load the Polymath preset',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _applyPolymathPreset,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Load Polymath 24h Schedule'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final block = blocks[index];
                        final isNow = block.isNow();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _showAddEditBlockSheet(block: block),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isNow
                                      ? block.color
                                      : (isDark ? const Color(0xFF2C2C34) : const Color(0xFFECECF0)),
                                  width: isNow ? 1.8 : 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left color stripe
                                  Container(
                                    width: 6,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: block.color,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(14),
                                        bottomLeft: Radius.circular(14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Time Box
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        block.startTime,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        block.endTime,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                block.title,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isNow)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6, right: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: block.color.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'NOW',
                                                  style: TextStyle(
                                                    color: block.color,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF282830) : const Color(0xFFECECF0),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                block.category,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              block.formattedDuration,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                              ),
                                            ),
                                            if (block.notes != null && block.notes!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.notes_rounded,
                                                size: 13,
                                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                                    onPressed: () => _showAddEditBlockSheet(block: block),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: blocks.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading routine: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBlockSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Block'),
      ),
    );
  }

  void _showAddEditBlockSheet({RoutineBlock? block}) {
    final titleCtrl = TextEditingController(text: block?.title ?? '');
    final notesCtrl = TextEditingController(text: block?.notes ?? '');
    String startTime = block?.startTime ?? '08:00';
    String endTime = block?.endTime ?? '09:30';
    String category = block?.category ?? 'Deep Work';
    int colorValue = block?.colorValue ?? 0xFF6366F1;

    final categories = ['Morning', 'Deep Work', 'Health', 'Learning', 'Evening', 'Sleep', 'Rest', 'Meals'];
    final colors = [
      0xFF6366F1, // Indigo
      0xFF10B981, // Emerald
      0xFFF59E0B, // Amber
      0xFFEC4899, // Pink
      0xFF8B5CF6, // Purple
      0xFF06B6D4, // Cyan
      0xFFEF4444, // Red
      0xFF64748B, // Slate
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    block == null ? 'Add 24h Time Block' : 'Edit Time Block',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  if (block != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () async {
                        await ref.read(routineRepositoryProvider).deleteRoutineBlock(block.id);
                        ref.invalidate(routineBlocksProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: block == null,
                decoration: const InputDecoration(
                  labelText: 'Block Title',
                  hintText: 'e.g. Polymath Deep Study, Morning Workout',
                ),
              ),
              const SizedBox(height: 14),
              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text('Start: $startTime'),
                      onPressed: () async {
                        final parts = startTime.split(':').map(int.parse).toList();
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
                        );
                        if (t != null) {
                          setSheetState(() {
                            startTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                      label: Text('End: $endTime'),
                      onPressed: () async {
                        final parts = endTime.split(':').map(int.parse).toList();
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(hour: parts[0], minute: parts[1]),
                        );
                        if (t != null) {
                          setSheetState(() {
                            endTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Category chips
              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final selected = category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setSheetState(() => category = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Color selector
              const Text('Accent Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: colors.map((col) {
                  final isSel = colorValue == col;
                  return GestureDetector(
                    onTap: () => setSheetState(() => colorValue = col),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(col),
                        shape: BoxShape.circle,
                        border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                      ),
                      child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Protocol (Optional)',
                  hintText: 'e.g. Phone on Do Not Disturb, drink 500ml water',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    final newBlock = RoutineBlock(
                      id: block?.id ?? _uuid.v4(),
                      title: title,
                      startTime: startTime,
                      endTime: endTime,
                      category: category,
                      colorValue: colorValue,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    );

                    await ref.read(routineRepositoryProvider).saveRoutineBlock(newBlock);
                    ref.invalidate(routineBlocksProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(block == null ? 'Save Routine Block' : 'Update Block'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyPolymathPreset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply Polymath Schedule?'),
        content: const Text(
          'This will populate a full 24-hour circadian schedule optimized for deep focus, polymath study, physical fitness, and restorative sleep.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply Preset')),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(routineRepositoryProvider);
    final presetBlocks = [
      RoutineBlock(id: _uuid.v4(), title: 'Sleep & Physical Recovery', startTime: '00:00', endTime: '06:30', category: 'Sleep', colorValue: 0xFF64748B),
      RoutineBlock(id: _uuid.v4(), title: 'Wake Up, Sunlight & Hydrate', startTime: '06:30', endTime: '07:00', category: 'Morning', colorValue: 0xFFF59E0B),
      RoutineBlock(id: _uuid.v4(), title: 'Movement, Yoga & Workout', startTime: '07:00', endTime: '08:00', category: 'Health', colorValue: 0xFF10B981),
      RoutineBlock(id: _uuid.v4(), title: 'Nutritious Breakfast & Planning', startTime: '08:00', endTime: '08:45', category: 'Meals', colorValue: 0xFF06B6D4),
      RoutineBlock(id: _uuid.v4(), title: 'Deep Work Block I (High Cognitive)', startTime: '08:45', endTime: '12:00', category: 'Deep Work', colorValue: 0xFF6366F1),
      RoutineBlock(id: _uuid.v4(), title: 'Healthy Lunch & Decompression Walk', startTime: '12:00', endTime: '13:00', category: 'Meals', colorValue: 0xFF10B981),
      RoutineBlock(id: _uuid.v4(), title: 'Deep Work Block II / Coding & Building', startTime: '13:00', endTime: '16:00', category: 'Deep Work', colorValue: 0xFF6366F1),
      RoutineBlock(id: _uuid.v4(), title: 'Polymath Study & Cross-Discipline Reading', startTime: '16:00', endTime: '18:00', category: 'Learning', colorValue: 0xFF8B5CF6),
      RoutineBlock(id: _uuid.v4(), title: 'Light Cardio / Social / Errands', startTime: '18:00', endTime: '19:30', category: 'Health', colorValue: 0xFFEC4899),
      RoutineBlock(id: _uuid.v4(), title: 'Dinner & Mindful Evening', startTime: '19:30', endTime: '20:45', category: 'Evening', colorValue: 0xFFF59E0B),
      RoutineBlock(id: _uuid.v4(), title: 'Daily Reflection & Screen Wind-Down', startTime: '20:45', endTime: '22:00', category: 'Evening', colorValue: 0xFF8B5CF6),
      RoutineBlock(id: _uuid.v4(), title: 'Sleep & Night Recovery', startTime: '22:00', endTime: '24:00', category: 'Sleep', colorValue: 0xFF64748B),
    ];

    for (final b in presetBlocks) {
      await repo.saveRoutineBlock(b);
    }
    ref.invalidate(routineBlocksProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polymath 24h routine loaded successfully!')),
      );
    }
  }
}
