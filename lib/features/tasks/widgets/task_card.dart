import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/time_utils.dart';
import '../providers/task_provider.dart';

/// Material 3 Expressive task list card for Life OS.
/// Features:
/// - Tactile squircle checkbox with animated completion state
/// - Clear typographic hierarchy and generous breathing room
/// - Expressive micro-pills for timing, priority, subtasks, and recurrence
/// - Uncrowded, calm scannability
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
    final primary = Theme.of(context).colorScheme.primary;
    final isDone = task.isCompleted;

    // Semantic priority color
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151518) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF24242A) : const Color(0xFFE6E6EA),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Tactile Checkbox (M3 Expressive Squircle)
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
                      width: 30,
                      height: 30,
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
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
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
                          height: 1.3,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone
                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Metadata row: Expressive, spacious pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Timing Pill
                          if (task.isAllDay) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'All Day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ),
                          ] else if (task.scheduledTime != null && task.scheduledTime!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF202025) : const Color(0xFFF0F0F4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    TimeUtils.formatTo12Hour(task.scheduledTime!),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Top Focus Star Chip
                          if (task.isTopFocus)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Top Focus',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Priority Micro-Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
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
                                    fontWeight: FontWeight.w700,
                                    color: priorityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Subtasks count
                          if (task.subtasks.isNotEmpty) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Recurrence indicator
                          if (task.recurrence != 'none' && task.recurrence.isNotEmpty) ...[
                            Icon(
                              Icons.repeat_rounded,
                              size: 13,
                              color: primary,
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
