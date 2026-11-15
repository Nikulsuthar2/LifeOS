import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/task_provider.dart';

/// Minimal, modern Cupertino / Things-3 inspired task list item for Life OS.
/// - Crisp squircle checkbox with tactile completion state
/// - Typography-led visual hierarchy with zero container clutter
/// - Subtle micro-badges for priority, time, and subtasks
/// - Description preview removed to ensure scannability and calm spacing
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

    // Priority color mapping
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = AppColors.urgent;
        break;
      case TaskPriority.high:
        priorityColor = AppColors.high;
        break;
      case TaskPriority.medium:
        priorityColor = AppColors.medium;
        break;
      case TaskPriority.low:
        priorityColor = AppColors.low;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141416) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF242428) : const Color(0xFFE5E5EA),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Tactile Squircle Checkbox (Enlarged 28x28 Things-3 style)
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
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDone
                              ? AppColors.success
                              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFC7C7CC)),
                          width: 1.8,
                        ),
                      ),
                      child: isDone
                          ? const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                ),

                // 2. Title & Calm Minimal Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Metadata row: Essential context only
                      Row(
                        children: [
                          // Timing: All-Day capsule or Scheduled Time
                          if (task.isAllDay) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
                            ),
                            const SizedBox(width: 8),
                          ] else if (task.scheduledTime != null && task.scheduledTime!.isNotEmpty) ...[
                            Icon(
                              CupertinoIcons.clock,
                              size: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              task.scheduledTime!,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Priority Micro-Badge (dot + label)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: priorityColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.priority.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),

                          // Subtasks count (only if present)
                          if (task.subtasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.list_bullet,
                              size: 11,
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

                          // Recurrence indicator
                          if (task.recurrence != 'none' && task.recurrence.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              CupertinoIcons.repeat,
                              size: 12,
                              color: AppColors.primaryLight,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                if (trailing != null) ...[
                  const SizedBox(width: 8),
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
