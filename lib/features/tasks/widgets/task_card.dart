import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/priority_badge.dart';
import '../providers/task_provider.dart';

/// Refined, minimal, typography-led task list item for Life OS.
/// Features:
/// - Rectangular rounded checkbox (no circular radio)
/// - Clean title and scannable metadata
/// - Description preview removed to eliminate clutter and crowding
/// - Generous breathing room and whitespace
class TaskCard extends ConsumerWidget {
  final TaskItem task;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rectangular Checkbox with generous touch target
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final repo = ref.read(taskRepositoryProvider);
                    await repo.toggleTaskCompletion(task.id, !isDone);
                    ref.invalidate(tasksListProvider);
                    ref.invalidate(calendarTasksProvider);
                    ref.invalidate(topPrioritiesProvider);
                    ref.invalidate(todayTaskMetricsProvider);
                    ref.invalidate(weekTaskDatesProvider);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(5), // Clean rectangular checkbox
                        border: Border.all(
                          color: isDone
                              ? AppColors.success
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 1.8,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 15, color: Colors.white)
                          : null,
                    ),
                  ),
                ),

                // Title & Calm Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.15,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Metadata Row (Generous spacing, crisp tags)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // All Day indicator or Scheduled Time
                          if (task.isAllDay)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'All Day',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            )
                          else if (task.scheduledTime != null && task.scheduledTime!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  task.scheduledTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),

                          // Priority
                          PriorityBadge(priority: task.priority),

                          // Duration
                          if (task.estimateMinutes > 0 && !task.isAllDay)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.estimateMinutes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),

                          // Subtasks count
                          if (task.subtasks.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist,
                                  size: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),

                          // Recurrence badge
                          if (task.recurrence != 'none')
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 12,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  task.recurrence,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),

                          // Due date if different from today
                          if (task.dueDate != null)
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: task.dueDate!.isBefore(DateTime.now()) && !isDone
                                    ? AppColors.urgent
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
