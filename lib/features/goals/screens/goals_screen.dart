import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/goal_project.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/goal_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedCategory = 'All';

  void _showAddGoalDialog({Goal? existingGoal}) {
    final titleController = TextEditingController(text: existingGoal?.title ?? '');
    final descController = TextEditingController(text: existingGoal?.description ?? '');
    String category = existingGoal?.category ?? 'Career';
    DateTime? targetDate = existingGoal?.targetDate;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingGoal != null ? 'Edit Goal' : 'New Life Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g. Master AI Engineering, Run Marathon',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Why this goal matters',
                    hintText: 'Core motivation and desired outcome...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Career', 'Health', 'Finance', 'Learning', 'Personal', 'Creativity'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      targetDate != null
                          ? 'Target: ${DateFormat('MMM yyyy').format(targetDate!)}'
                          : 'No target deadline',
                      style: const TextStyle(fontSize: 13),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: targetDate ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setDialogState(() => targetDate = picked);
                      },
                      child: const Text('Pick Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final repo = ref.read(goalRepositoryProvider);
                if (existingGoal != null) {
                  final updated = existingGoal.copyWith(
                    title: title,
                    description: descController.text.trim(),
                    category: category,
                    targetDate: targetDate,
                  );
                  await repo.updateGoal(updated);
                } else {
                  final newGoal = Goal(
                    id: const Uuid().v4(),
                    title: title,
                    description: descController.text.trim(),
                    category: category,
                    targetDate: targetDate,
                  );
                  await repo.insertGoal(newGoal);
                }

                ref.invalidate(goalsListProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              },
              child: Text(existingGoal != null ? 'Save' : 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMilestoneDialog(String goalId) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Milestone'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Complete System Design course',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final milestone = Milestone(
                id: const Uuid().v4(),
                goalId: goalId,
                title: title,
              );
              await ref.read(goalRepositoryProvider).insertMilestone(milestone);
              ref.invalidate(goalsListProvider);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final goalsAsync = ref.watch(goalsListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Life Goals & Milestones',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: primary,
        foregroundColor: ThemeData.estimateBrightnessForColor(primary) == Brightness.light
            ? const Color(0xFF141416)
            : Colors.white,
        icon: const Icon(Icons.flag_rounded),
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: ['All', 'Career', 'Health', 'Finance', 'Learning', 'Personal', 'Creativity'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    visualDensity: VisualDensity.compact,
                    selectedColor: primary.withValues(alpha: 0.2),
                    checkmarkColor: primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Goals list
          Expanded(
            child: goalsAsync.when(
              data: (goals) {
                final filtered = _selectedCategory == 'All'
                    ? goals
                    : goals.where((g) => g.category == _selectedCategory).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No goals in this category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + New Goal to establish your vision.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final goal = filtered[index];
                    final progress = goal.progressPercentage;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16161A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF26262C) : const Color(0xFFE5E5EA),
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Category, Target Date, Actions
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  goal.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (goal.targetDate != null) ...[
                                Icon(Icons.event_outlined, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM yyyy').format(goal.targetDate!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit',
                                onPressed: () => _showAddGoalDialog(existingGoal: goal),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  await ref.read(goalRepositoryProvider).deleteGoal(goal.id);
                                  ref.invalidate(goalsListProvider);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title & Description
                          Text(
                            goal.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                          ),
                          if (goal.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              goal.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: isDark ? const Color(0xFF26262C) : const Color(0xFFE8E8EC),
                                    valueColor: AlwaysStoppedAnimation(
                                      progress == 1.0 ? AppColors.success : primary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: progress == 1.0 ? AppColors.success : primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Milestones Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MILESTONES (${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length})',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              InkWell(
                                onTap: () => _showAddMilestoneDialog(goal.id),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    '+ Add Milestone',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          ...goal.milestones.map((milestone) {
                            return InkWell(
                              onTap: () async {
                                await ref.read(goalRepositoryProvider).toggleMilestone(
                                      milestone.id,
                                      !milestone.isCompleted,
                                    );
                                ref.invalidate(goalsListProvider);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      milestone.isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 16,
                                      color: milestone.isCompleted ? AppColors.success : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        milestone.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          decoration: milestone.isCompleted ? TextDecoration.lineThrough : null,
                                          color: milestone.isCompleted
                                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 14),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        await ref.read(goalRepositoryProvider).deleteMilestone(milestone.id);
                                        ref.invalidate(goalsListProvider);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
