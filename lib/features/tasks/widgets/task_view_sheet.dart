import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/task.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/time_utils.dart';
import '../../track/focus/providers/focus_provider.dart';
import '../../track/focus/screens/focus_screen.dart';
import '../models/recurrence_engine.dart';
import '../providers/task_provider.dart';
import '../screens/task_detail_screen.dart';

/// Read-only Task Preview Bottom Sheet with Material 3 Expressive design.
/// - Uncluttered, typography-led task overview
/// - Interactive subtasks checklist directly below description
/// - Clean, readable metadata cards with spacious padding
/// - Two prominent M3 action buttons: "Focus Pomodoro" and "Edit Task"
class TaskViewSheet extends ConsumerStatefulWidget {
  final TaskItem task;

  const TaskViewSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, TaskItem task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskViewSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskViewSheet> createState() => _TaskViewSheetState();
}

class _TaskViewSheetState extends ConsumerState<TaskViewSheet> {
  late TaskItem _task;
  late List<Subtask> _subtasks;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _subtasks = List.from(widget.task.subtasks);
  }

  Future<void> _toggleTaskCompletion() async {
    final nextStatus = !_task.isCompleted;
    setState(() {
      _task = _task.copyWith(
        status: nextStatus ? TaskStatus.completed : TaskStatus.todo,
        completedAt: nextStatus ? DateTime.now() : null,
      );
    });

    final repo = ref.read(taskRepositoryProvider);
    await repo.toggleTaskCompletion(_task.id, nextStatus);
    ref.invalidate(tasksListProvider);
    ref.invalidate(calendarTasksProvider);
  }

  Future<void> _toggleSubtask(Subtask subtask) async {
    final nextCompleted = !subtask.isCompleted;
    setState(() {
      final idx = _subtasks.indexWhere((s) => s.id == subtask.id);
      if (idx != -1) {
        _subtasks[idx] = subtask.copyWith(isCompleted: nextCompleted);
      }
    });

    final repo = ref.read(taskRepositoryProvider);
    await repo.toggleSubtaskCompletion(subtask.id, nextCompleted);
    ref.invalidate(tasksListProvider);
    ref.invalidate(calendarTasksProvider);
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return AppColors.urgent;
      case TaskPriority.high:
        return AppColors.high;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.low;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final priorityColor = _getPriorityColor(_task.priority);
    final completedSubtasksCount = _subtasks.where((s) => s.isCompleted).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161619) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333338) : const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
              child: Row(
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_task.priority.displayName.toUpperCase()} PRIORITY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_task.isTopPriority) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            'TOP FOCUS',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  IconButton.filledTonal(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF222226) : const Color(0xFFF0F0F4),
                      foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? const Color(0xFF24242A) : const Color(0xFFEBEBF0),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Task Title & Completion Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleTaskCompletion,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 2, right: 14),
                            decoration: BoxDecoration(
                              color: _task.isCompleted
                                  ? AppColors.success
                                  : (isDark ? const Color(0xFF222226) : const Color(0xFFF0F0F4)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _task.isCompleted
                                    ? AppColors.success
                                    : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFC7C7CC)),
                                width: 1.8,
                              ),
                            ),
                            child: _task.isCompleted
                                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _task.title,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.3,
                              decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                              color: _task.isCompleted
                                  ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 2. Task Description (if any)
                    if (_task.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF28282E) : const Color(0xFFE8E8EC),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _task.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // 3. Subtasks Checklist
                    if (_subtasks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SUBTASKS ($completedSubtasksCount/${_subtasks.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          Text(
                            '$completedSubtasksCount of ${_subtasks.length} done',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF7F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? const Color(0xFF28282E) : const Color(0xFFE6E6EA),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          children: _subtasks.map((s) {
                            return InkWell(
                              onTap: () => _toggleSubtask(s),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22,
                                      height: 22,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: s.isCompleted ? AppColors.success : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: s.isCompleted
                                              ? AppColors.success
                                              : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFC7C7CC)),
                                          width: 1.6,
                                        ),
                                      ),
                                      child: s.isCompleted
                                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        s.title,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                                          color: s.isCompleted
                                              ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 4. Metadata Details Card (Read-Only)
                    Text(
                      'DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28282E) : const Color(0xFFE6E6EA),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Date & Time
                          _buildDetailRow(
                            isDark: isDark,
                            icon: Icons.calendar_today_rounded,
                            iconColor: primary,
                            label: 'Date & Time',
                            value: _task.dueDate != null
                                ? (_task.isAllDay
                                    ? '${DateFormat('EEE, MMM d, yyyy').format(_task.dueDate!)} · All Day'
                                    : '${DateFormat('EEE, MMM d, yyyy').format(_task.dueDate!)} · ${TimeUtils.formatTo12Hour(_task.scheduledTime)}')
                                : 'No date set',
                            isFirst: true,
                          ),

                          // Duration
                          _buildDetailRow(
                            isDark: isDark,
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFFF97316),
                            label: 'Duration',
                            value: '${_task.estimateMinutes} min',
                          ),

                          // Recurrence
                          if (_task.recurrence != 'none' && _task.recurrence.isNotEmpty)
                            _buildDetailRow(
                              isDark: isDark,
                              icon: Icons.repeat_rounded,
                              iconColor: AppColors.secondary,
                              label: 'Repeats',
                              value: RecurrenceEngine.formatDescription(_task),
                            ),

                          // Deadline
                          if (_task.endDate != null)
                            _buildDetailRow(
                              isDark: isDark,
                              icon: Icons.flag_outlined,
                              iconColor: AppColors.urgent,
                              label: 'Deadline',
                              value: DateFormat('MMM d, yyyy').format(_task.endDate!),
                            ),

                          // Linked Topic / Project
                          if (_task.roadmapTopicId != null && _task.roadmapTopicId!.isNotEmpty)
                            _buildDetailRow(
                              isDark: isDark,
                              icon: Icons.link_rounded,
                              iconColor: AppColors.accent,
                              label: 'Linked Topic',
                              value: 'Learning Roadmap Item',
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),

            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? const Color(0xFF24242A) : const Color(0xFFEBEBF0),
            ),

            // 5. Two Action Buttons: "Open in Focus" & "Edit Task"
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Row(
                children: [
                  // Button 1: Open in Focus / Pomodoro
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.timer_rounded, size: 18),
                      label: const Text(
                        'Focus Pomodoro',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(focusTimerProvider.notifier).linkTask(_task.id, _task.title);
                        ref.read(focusTimerProvider.notifier).start();
                        FocusScreen.open(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(
                          color: primary.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Button 2: Edit Task
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text(
                        'Edit Task',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        TaskDetailScreen.open(context, _task).then((_) {
                          ref.invalidate(tasksListProvider);
                          ref.invalidate(calendarTasksProvider);
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: ThemeData.estimateBrightnessForColor(primary) == Brightness.light
                            ? const Color(0xFF141416)
                            : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF28282E) : const Color(0xFFE8E8EC),
                  width: 0.7,
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
